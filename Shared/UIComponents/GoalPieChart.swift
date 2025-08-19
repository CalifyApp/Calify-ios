//
//  GoalPieChart.swift
//  Calify
//
//  Created by justin lorenzo on 8/10/25.
//

import SwiftUI

struct DonutChartView: View {
    @State private var activeIndex: Int? = nil
    @FocusState private var focusedIndex: Int?
    @State private var inputValue: String = ""
    
    @State private var values: [Double] = [30, 30, 30]
    var colors: [Color]
    var centerCalories: Int = 2000

    var lineWidth: CGFloat = 30
    var labelDiameter: CGFloat = 36
    var labelPadding: CGFloat = 8

    var body: some View {
        let total = values.reduce(0, +)
        let fractions: [Double] = total > 0
            ? values.map { $0 / total }
            : Array(repeating: 0, count: values.count)

        var starts: [Double] = []
        var ends: [Double] = []
        var acc: Double = 0
        for f in fractions {
            starts.append(acc)
            acc += f
            ends.append(acc)
        }

        return GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)

            ZStack {
                ForEach(values.indices, id: \.self) { i in
                    let start = starts[i]
                    let end = ends[i]
                    let value = values[i]

                    if end - start > 0 {
                        Circle()
                            .trim(from: start, to: end)
                            .stroke(colors[i], style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                            .rotationEffect(.degrees(-90))
                    }

                    if value > 0 {
                        let midFraction = (start + end) / 2
                        let midAngle = Angle(degrees: midFraction * 360 - 90)
                        let labelRadius = radius + (lineWidth / 2) + labelPadding
                        let x = center.x + CGFloat(cos(midAngle.radians)) * labelRadius
                        let y = center.y + CGFloat(sin(midAngle.radians)) * labelRadius
                        let binding: Binding<Int> = Binding(
                            get: { Int(values[i]) },
                            set: { values[i] = Double($0) }
                        )

                        if activeIndex == i {
                            // In-place editable number
                            TextField(
                                "",
                                value: Binding(
                                    get: { values[i] },
                                    set: { values[i] = $0 }
                                ),
                                format: .number.precision(.fractionLength(0)) // Treat as whole numbers
                            )
                            .focused($focusedIndex, equals: i)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.caption2.weight(.semibold))
                            .frame(width: labelDiameter, height: labelDiameter)
                            .background(Circle().fill(Color(UIColor.systemBackground)))
                            .overlay(Circle().stroke(colors[i], lineWidth: 2))
                            .shadow(radius: 1)
                            .position(x: x, y: y)
                            .onAppear { focusedIndex = i }
                            .onSubmit { activeIndex = nil }
                        } else {
                            Text("\(Int(value))g")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .frame(width: labelDiameter, height: labelDiameter)
                                .background(Circle().fill(Color(UIColor.systemBackground)))
                                .overlay(Circle().stroke(colors[i], lineWidth: 2))
                                .shadow(radius: 1)
                                .position(x: x, y: y)
                                .onTapGesture {
                                    activeIndex = i
                                }
                        }
                    }
                }

                Text("\(centerCalories)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            
        }
        .frame(width: 220, height: 220)
    }
}





