//
//  NumberPad.swift
//  Calify
//
//  Created by justin lorenzo on 8/19/25.
//

import SwiftUI

struct NumberPad: UIViewRepresentable {
    @Binding var value: String
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.borderStyle = .roundedRect
        textField.delegate = context.coordinator
        
        DispatchQueue.main.async {
            textField.becomeFirstResponder() // automatically focus
        }
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var value: String
        
        init(value: Binding<String>) {
            _value = value
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            value = textField.text ?? ""
        }
    }
}
