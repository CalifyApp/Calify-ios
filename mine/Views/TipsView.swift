import SwiftUI

struct TipsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("How to Improve Your Meal Accuracy Score")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
                
                Text("Your accuracy score reflects how precise our calorie and macro estimates are based on the detail in your meal descriptions. The higher the score, the more confident we are in our estimates.")
                    .font(.body)
                
                // Tips Sections
                TipSection(
                    title: "Be Specific About Portions",
                    tips: [
                        "Mention exact quantities: \"2 cups of rice\" instead of \"some rice\"",
                        "Include weights when possible: \"6 oz salmon fillet\" rather than \"salmon\"",
                        "Specify measurements: \"3 tablespoons of olive oil\" vs \"oil\""
                    ]
                )
                
                TipSection(
                    title: "Include Preparation Methods",
                    tips: [
                        "Mention cooking techniques: \"grilled chicken\" vs \"chicken\"",
                        "Specify if foods are homemade or store-bought: \"homemade pasta sauce\" vs \"pasta sauce\"",
                        "Note if something is fried, baked, steamed, etc."
                    ]
                )
                
                TipSection(
                    title: "Be Descriptive About Ingredients",
                    tips: [
                        "List major ingredients in dishes: \"spinach salad with walnuts, feta, and cranberries\"",
                        "Mention brands when relevant: \"Kind protein bar\" vs \"protein bar\"",
                        "Include varieties/types: \"jasmine rice\" or \"red delicious apple\""
                    ]
                )
                
                TipSection(
                    title: "Add Context",
                    tips: [
                        "Note restaurant names for takeout/dining out",
                        "Mention if foods are packaged/processed or fresh",
                        "Include approximate sizes: \"large banana\" vs \"banana\""
                    ]
                )
                
                // Examples
                VStack(alignment: .leading, spacing: 12) {
                    Text("Examples")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    // Low accuracy example
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Low Accuracy")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("\"I had pasta for lunch\"")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                    
                    // High accuracy example
                    VStack(alignment: .leading, spacing: 6) {
                        Text("High Accuracy")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("\"I had 1.5 cups of cooked whole wheat penne pasta with 1/2 cup homemade tomato sauce, 2 tbsp grated parmesan, and a small side salad with balsamic vinaigrette\"")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.1))
                            )
                    }
                }
                
                // Footer reminder
                Text("Remember: You don't need to be perfect! Even small improvements in detail can significantly boost your accuracy score and give you more reliable nutrition information.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
            .padding()
        }
        .navigationTitle("Accuracy Tips")
    }
}

// Helper view for tip sections
struct TipSection: View {
    var title: String
    var tips: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .padding(.top, 6)
                    
                    Text(tip)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        TipsView()
    }
}
