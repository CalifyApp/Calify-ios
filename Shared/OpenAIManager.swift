import Foundation
import SwiftOpenAI

class OpenAIManager {
    static let shared = OpenAIManager()
    private let service: OpenAIService
    
    // Using an atomic property to store accuracy tips
    private let accuracyTipsQueue = DispatchQueue(label: "com.app.accuracyTips", attributes: .concurrent) //
    private var _accuracyTips: String = ""
    public var accuracyTips: String {
        get {
            var result: String = ""
            accuracyTipsQueue.sync { result = _accuracyTips } //wait until chatgpt gets result, before setting and returning result.
            return result
        }
        set {
            accuracyTipsQueue.async(flags: .barrier) { [weak self] in
                self?._accuracyTips = newValue
            }
        }
    }
    
    private init() {
        let apiKey = "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"
        self.service = OpenAIServiceFactory.service(apiKey: apiKey)
    }
    
    enum APIError: Error { //enum lets you define a group of related values (in this case, errors!)
        case emptyResponse(String) // these cases are custom labels. if i have to throw this error, itll include a string.
        case apiFailure(Error)
        case jsonParsingError(Error)
    }
    
    //at the same time we run raw response, we run fetch accuracytips.
    func rawResponse(meal: String) async -> Result<String, APIError> {
        
        //tasks run concurrently, so this runs on one thread concurrently.
        Task {
            await fetchAccuracyTips(meal: meal)
        }
        
        // Process main estimation and return it without waiting for accuracy tips
        do {
            let mainResult = try await processMainEstimation(meal: meal)
            return .success(mainResult)
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(.apiFailure(error))
        }
    }
    
    private func processMainEstimation(meal: String) async throws -> String {
        //prompt handling instructions for initial estimate.
        let estimatePrompt = """
 You are a calorie tracking expert. Estimate total calories and macros (protein, carbs, fat in grams) for any food input. Be accurate and include specific numbers. Assume standard portion sizes if needed. Never skip any items mentioned. Output should be clear, factual, and not overly polite or vague.
 
 If a user uses vague measurements like 'a cup,' 'a serving,' or 'an ounce,' standardize them to precise values like '1 cup,' '1 serving,' or '1 ounce.' Scale appropriately if the context implies more or less. The meal is:
 """
        
        let accuracyPrompt = """
Based on this meal description: "\(meal)"

Evaluate the precision of the information provided:

Assign a confidence score (accuracyScore) from 0-100 based on:
- Portion clarity (specific measurements vs vague amounts)
- Ingredient details (specific types/brands vs generic mentions)
- Preparation method information
- Comprehensive listing of components
- Overall descriptiveness

🔹 If the meal is simple, and does not require much detail (e.g a banana, or egg) because it does not vary in calories a lot, give a High accuracy score above 70. 

Higher scores mean more confident estimates. Lower scores indicate more assumptions were needed. For less descriptive, but branded meals, provide higher accuracy score for the user, since you know brand estimates.

Return only this in JSON Format, with NO BACKTICKS:
- accuracyScore: (int)
"""
        
        // Structure prompt definition moved here for logical ordering
        let structurePrompt = """
        Convert this text into JSON with keys: calories(int), protein(int), carbs(int), fat(int), accuracyScore(int), and description(string).
        Add into the description field a short description of the meal based off the meals description. Only return JSON. Do not include backticks. Use average values of calorie/macro estimates.
"""
        
        // Run estimate request
        let estimatePromptParameters = ChatCompletionParameters(
            messages: [.init(role: .user, content: .text(estimatePrompt + " " + meal))],
            model: .custom("gpt-4.1-2025-04-14"),
            temperature: 0.0
        )
        
        do {
            let estimateResponse = try await service.startChat(parameters: estimatePromptParameters)
            guard let estimateMessage = estimateResponse.choices.first?.message.content else {
                throw APIError.emptyResponse("Error: Empty response from estimate request")
            }
            
            // Run accuracy request
            let accuracyParameters = ChatCompletionParameters(
                messages: [.init(role: .user, content: .text(accuracyPrompt))],
                model: .custom("gpt-4.1-2025-04-14"),
                temperature: 0.0
            )
            
            let accuracyResponse = try await service.startChat(parameters: accuracyParameters)
            guard let accuracyMessage = accuracyResponse.choices.first?.message.content else {
                throw APIError.emptyResponse("Error: Empty response from accuracy request")
            }
            
            // Run structure request with proper variable references
            let structureParameters = ChatCompletionParameters(
                messages: [.init(role: .user, content: .text(structurePrompt + estimateMessage + accuracyMessage))],
                model: .custom("gpt-4.1-nano"),
                temperature: 0.0
            )
            
            let structureResponse = try await service.startChat(parameters: structureParameters)
            guard let finalMessage = structureResponse.choices.first?.message.content else {
                throw APIError.emptyResponse("Error: Empty response from structure formatting")
            }
            
            return finalMessage
        } catch {
            throw APIError.apiFailure(error)
        }
    }
    
    private func fetchAccuracyTips(meal: String) async {//TODO: POTENTIAL TIPS RACE CONDITION. FIX ASYNC
        let accuracyTipsPrompt = """
        Check out this meal description: "\(meal)"

        Your job is to help the user write more accurate food descriptions for calorie estimation.

        🔹 If the meal is already well-written, specific, and clear, respond only with:
        ["Looks great! No tips needed."]

        🔹 If the meal is vague or missing important details, return **2–3 concise suggestions** in a JSON array.
        
        Focus only on:
        - Portion clarity
        - Ingredient specificity (type/brand)
        - Cooking method
        - Completeness of all components
        - Overall descriptiveness

        ❗️Avoid nitpicking. Do NOT give tips for things the user already clearly described. Do NOT suggest minor or unnecessary improvements.

        Output format: a JSON array of 2–3 bullet points contained in strings or the exact phrase ["Looks great! No tips needed."] — no extra text, no backticks.

        """
        
        let accuracyTipsParams = ChatCompletionParameters(
            messages: [.init(role: .user, content: .text(accuracyTipsPrompt))],
            model: .gpt4o,
            temperature: 0.0
        )
        
        do {
            let tipsResponse = try await service.startChat(parameters: accuracyTipsParams)
            if let tipsContent = tipsResponse.choices.first?.message.content {
                self.accuracyTips = tipsContent // Store raw string JSON
            }
        } catch {
            // Log error but don't fail the entire process
            print("Error fetching accuracy tips: \(error.localizedDescription)")
            //TODO: Fix this bs
            self.accuracyTips = """
            {"accuracyScore": 0, "tips": ["Unable to generate tips due to an error"]}
            """
        }
    }
    
    // Method to get the raw JSON string for tips
    func getRawAccuracyTips() -> String {
        return self.accuracyTips
    }
}
