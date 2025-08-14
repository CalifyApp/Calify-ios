import Supabase
import Foundation

class SupabaseManager {
    static let shared = SupabaseManager() //Singleton instance of SupabaseManager for global access
    
    let client: SupabaseClient
    struct Response: Decodable {
        
    }
    struct DayTotal { let day: Date; let total: Int }

    
    private init() {
    
        let url = URL(string: "https://ypzdjlfgckfyqqhyhgjc.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwemRqbGZnY2tmeXFxaHloZ2pjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM0NzM5MTYsImV4cCI6MjA1OTA0OTkxNn0.hv8kcWuQJsRXCswZFad2YAONTouzUat6rlwpU0CEX_s"
        
        let options = SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                storage: AuthClient.Configuration.defaultLocalStorage,
                autoRefreshToken: true
            )
        )
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: options
        )
    }
    
    
    func getUserId() async throws -> UUID {
        let auth = client.auth
        try await print(auth.session)

        do {
            if let currentSession = try? await auth.session {
                return currentSession.user.id
            } else {
                // Try to refresh session
                try await auth.refreshSession()
                if let refreshedSession = try? await auth.session {
                    print("🔄 Refreshed session")
                    return refreshedSession.user.id
                } else {
                    // Still no session? Then sign in again
                    let newSession = try await auth.signInAnonymously()
                    print("🆕 Signed in anonymously after refresh failed")
                    return newSession.user.id
                }
            }
        } catch {
            print("❌ Failed to get or refresh session: \(error)")
            throw error
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
    
    func insertMeal(description: String, calories: Int, protein: Int, carbs: Int, fat: Int, accuracyScore: Int, tips: [String]) async throws {
        do {
            let userId = try await self.getUserId()

            let meal = MealEstimate(
                id: nil, //auto generated, can be nil.
                user_id: userId,
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
            
//            try await client.from("Meals").insert(meal).execute()
            let insertedMeal: MealEstimate = try await client
                .from("Meals")
                .insert(meal)
                .select()
                .single()
                .execute()
                .value
            
            await MainActor.run {
                MealCacheManager.shared.addMeal(insertedMeal)
            }
            
            
        } catch {
            print("Error inserting meals into database: ", error)
            throw error
        }
        
    }
    
    func insertMeal(description: String, calories: Int, protein: Int, carbs: Int, fat: Int, accuracyScore: Int, tips: [String], created_at: Date)  async throws { //This will insert a new meal into the database.
        do {
            let userId = try await self.getUserId()
            
            let meal = MealEstimate(
                id: nil,
                user_id: userId,
                protein: protein,
                carbs: carbs,
                fat: fat,
                calories: calories,
                description: description,
                accuracyScore: accuracyScore,
                accuracyFeedback: nil,
                created_at: created_at,
                tips: tips
            )
            
//            try await client.from("Meals").insert(meal).execute()
            let insertedMeal: MealEstimate = try await client
                .from("Meals")
                .insert(meal)
                .select()
                .single()
                .execute()
                .value
            
            await MainActor.run {
                MealCacheManager.shared.addMeal(insertedMeal, for: created_at)
            }
            
            
        } catch {
            print("Error inserting meals into database: ", error)
            throw error
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
    func fetchMealsForWeek(for frame: TimeFrame) async throws -> [DayTotal] {
        let userId = try await self.getUserId()
        
        var cal = Calendar.current //make sure we respect user timeozone.
        cal.firstWeekday = 2
        cal.timeZone = .current
        
        //Go back N weeks from today
        let base = cal.date(byAdding: .weekOfYear, value: -frame.weeksAgo, to: Date())!
        
        // Step 2: Snap to Monday 00:00 of that week
        let weekComps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base)
        let startOfWeek = cal.date(from: weekComps)!
           
        // Step 3: End of week = next Monday 00:00 (exclusive upper bound)
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        // Local JSONDecoder that handles Supabase ISO8601 with fractional seconds (UTC)
        let decoder: JSONDecoder = {
            let d = JSONDecoder()

            let isoFrac = ISO8601DateFormatter()
            isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            isoFrac.timeZone = TimeZone(secondsFromGMT: 0)

            let isoPlain = ISO8601DateFormatter()
            isoPlain.formatOptions = [.withInternetDateTime]
            isoPlain.timeZone = TimeZone(secondsFromGMT: 0)

            d.dateDecodingStrategy = .custom { dec in
                let c = try dec.singleValueContainer()
                let s = try c.decode(String.self)
                if let dt = isoFrac.date(from: s) { return dt }    // e.g. ...56.123456Z
                if let dt = isoPlain.date(from: s) { return dt }   // e.g. ...56+00:00
                throw DecodingError.dataCorruptedError(in: c, debugDescription: "Bad date: \(s)")
            }
            return d
        }()

        
        let response = try await client
            .from("Meals")
            .select("created_at, calories")
            .eq("user_id", value: userId)
            .gte("created_at", value: startOfWeek.ISO8601Format())
            .lt("created_at", value: endOfWeek.ISO8601Format())
            .order("created_at", ascending: true)
            .execute()
        
        let meals = try decoder.decode([ChartMeal].self, from: response.data)

        
        var totals: [Date: Int] = [:]
        for m in meals {
            let day = cal.startOfDay(for: m.created_at) //day is, the day that that meal was created. and for every meal...
            totals[day, default: 0] += m.calories
        }
        
        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: i, to: startOfWeek)!
            return DayTotal(day: d, total: totals[d] ?? 0)
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
extension TimeFrame {
    var weeksAgo: Int {
        switch self {
            
        case .thisWeek: return 0
        case .lastWeek: return 1
        case .twoWeeksAgo: return 2
        case .threeWeeksAgo: return 3
            
        }
    }
}
