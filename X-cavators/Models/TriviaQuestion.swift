//
//  TriviaQuestion.swift
//  X-cavators
//
//  Model for archaeology trivia questions used in the repair mini-game
//

import Foundation

struct TriviaQuestion: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]          // Always exactly 4 elements
    let correctAnswerIndex: Int    // 0-based index into options
    let hint: String?              // Revealed when hint button is tapped
    let funFact: String?           // Shown after answering

    var correctAnswer: String {
        options[correctAnswerIndex]
    }
}
