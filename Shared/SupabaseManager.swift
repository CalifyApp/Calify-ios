import Supabase
import Foundation

class SupabaseManager {
    static let shared = SupabaseManager() //Singleton instance of SupabaseManager for global access
    
    let client: SupabaseClient
    struct Response: Decodable {
        
    }
    
    private init() {
        
        let url = URL(string: "https://ypzdjlfgckfyqqhyhgjc.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwemRqbGZnY2tmeXFxaHloZ2pjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM0NzM5MTYsImV4cCI6MjA1OTA0OTkxNn0.hv8kcWuQJsRXCswZFad2YAONTouzUat6rlwpU0CEX_s"
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }
    
    func getUserId()async throws -> UUID {
        let auth = client.auth //user signed in. grab it
        
        do {
            if let currentSession = try? await auth.session {
                print("We are anonymously logged in")
                return currentSession.user.id
            } else {
                let newSession = try await auth.signInAnonymously()
                print("For some reason, we arent signed in.... signing in now.")
                return newSession.user.id
            }
        } catch {
            print("Failed to get session: \(error)")
            throw error //Re-throw error for proper upstream handling.
        }
    }
    
    func getProfilesInfo() async throws -> Profiles? {
        do {
            let userId = try await SupabaseManager.shared.getUserId()
            print(userId)
            let response: [Profiles] = try await SupabaseManager.shared.client
                .from("Profiles")
                .select()
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value
            if let profile = response.first {
                print("Profile found!")
                return profile
            } else {
                print("No profile found - creating new one...")
                let newProfile = Profiles(
                    id: userId,
                    created_at: nil, // DB will auto-timestamp if configured correctly
                    name: "Bob",     // or "New Profile" etc
                    cal_goal: 2000,
                    protein_goal: 150,
                    fat_goal: 70,
                    carb_goal: 250
                )
                
                // 3. Insert into Supabase
                _ = try await SupabaseManager.shared.client
                    .from("Profiles")
                    .insert([newProfile])
                    .execute()
                
                print("✅ New profile inserted")
                
                // 4. Return the profile (assume insert worked) TODO: NEVER ASSUME
                return newProfile
            }
            
        } catch {
            print("Failed to fetch profile: \(error)")
            throw error
        }
    }
    
    func insertMeal(accessToken: String, description: String, calories: Int, protein: Int, carbs: Int, fat: Int, accuracyScore: Int, tips: [String]) async throws { //This will insert a new meal into the database.
        do {
        //TODO. Handle watch/iphone access token more gracefully.
            let user = try await client.auth.user(jwt: accessToken)
            print("Insert meal function shows userid", user.id)
            let meal = MealEstimate(
                id: nil, //auto generated, can be nil.
                user_id: user.id,
                protein: protein,
                carbs: carbs,
                fat: fat,
                calories: calories,
                description: description,
                accuracyScore: accuracyScore,
                accuracyFeedback: nil,
                created_at: nil,
                tips: tips
            )
            
            try await client.from("Meals").insert(meal).execute()
            print("insertion successful")
        } catch {
            print("Error inserting meals into database: ", error)
        }
        
    }
    
    func fetchMeals(for date: Date = Date()) async throws -> [MealEstimate] {
        do {
            let userId = try await self.getUserId()
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            
            let meals: [MealEstimate] = try await client
                .from("Meals") //1. display meals
                .select()
                .eq("user_id", value: userId)
                .gte("created_at", value: startOfDay.ISO8601Format()) //2. starting from this day
                .lt("created_at", value: endOfDay.ISO8601Format()) //3. limit to this day
                .order("created_at", ascending: false)
                .execute()
                .value //generic property returning decoded type that was declared (here, its meal estimate.)
            
            return meals
            
        } catch {
            print("Error fetching today's meals: \(error)")
            throw error
        }
        
    }
    
    func mealLimit() async throws -> Bool {
        do {
            let mealsArray = try await fetchMeals(for: Date()) // get today’s meals
            
            // Return true if user has exceeded the limit
            return mealsArray.count >= 15
        } catch {
            print("❌ Error checking meal limit: \(error)")
            throw error
        }
    }
    
    func deleteMeal(id: Int) async { //This will delete a meal from the database.
        do {
            
            try await client.from("Meals").delete().eq("id", value: id).execute()
            
            print("deletion successful")
        } catch {
            print("Error deleting meal from database: ", error)
        }
    }
    enum APIError: Error { //enum lets you define a group of related values (in this case, errors!)
        case emptyResponse(String) // these cases are custom labels. if i have to throw this error, itll include a string.
        case apiFailure(Error)
        case jsonParsingError(Error)
    }
    func callOpenAI(meal: String) async -> Result<String, APIError> {
        do {
            let response = try await client.functions.invoke(
                "OpenAIManager",
                options: FunctionInvokeOptions(
                    body: ["meal": meal]
                )
            ) { data, response in
                //This decode closure tells it how to handle res
                //Return data as string.
                String(data: data, encoding: .utf8) ?? "{}"
            }
            return .success(response)
                        
        } catch {
            return .failure(.apiFailure(error))
        }
    }
    
    func updateMealFeedback(feedback: String, mealId: Int) async {
        do {
            let userId = try await self.getUserId()
            
            let response = try await client
                .from("Meals")
                .update(["accuracyFeedback": feedback])
                .eq("id", value: mealId)
                .eq("user_id", value: userId)
                .execute()
            
            print("feedback updated successfully")
            
        } catch {
           print("Error updating feedback: ", error)
        }
    }
    func manualTokenRefreshUponExpiration() async {
            do {
                //see if jwt is valid.

                print("lets see if our token is still valid. Checking session...")
                _ = try await SupabaseManager.shared.client.auth.user() //if jwt is invalid, itll jump to the catch block. TODO: Test this.
                print("if we make it here, our tokens still valid, lets reset all tokens anyways. and store in user defaults.")
                let session = try await SupabaseManager.shared.client.auth.session
                let accessToken = session.accessToken
                let refreshToken = session.refreshToken
                print("session: ", session)
                //Save to userdefaults for watch to read
                UserDefaults.standard.set(accessToken, forKey: "accessToken")
                UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
                print("Token still valid, restored tokens in userDefaults ")
                
                        
            } catch {
                //JWT wasnt valid, or other issue with getting cur session.
                do {
                        print("our tokens were NOT valid... lets try refreshing the session. ")
                        try await SupabaseManager.shared.client.auth.refreshSession()

                        let session = try await SupabaseManager.shared.client.auth.session
                        let accessToken = session.accessToken
                        let refreshToken = session.refreshToken

                        UserDefaults.standard.set(accessToken, forKey: "accessToken")
                        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
                        print("session refresh successful! Successfully stored new access tokens bc of invalid session.")
                    } catch {
                        print("❌ Failed to refresh session. Critical Error: \(error)")
                    }
            }
        
    }
    
    
    
}
