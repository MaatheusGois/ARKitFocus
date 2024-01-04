//
//  FocusARSCNView.swift
//  ARKitFocus
//
//  Created by Matheus Gois on 04/01/24.
//

import ARKit
import SceneKit
import UIKit

class FocusARSCNView: ARSCNView {

    lazy var addObjectButton = buildAddButton()
    lazy var restartExperienceButton = buildResetButton()

    // Add any custom properties or methods here

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    func showDebug() {
        // Show statistics such as fps and timing information
        showsStatistics = true

        // Set the debug options (optional, depending on your needs)
        debugOptions = [
            ARSCNDebugOptions.showFeaturePoints,
            ARSCNDebugOptions.showWorldOrigin
        ]
    }
}

extension FocusARSCNView {
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false

        addObjectButton.setTitle("Add", for: .normal)
        restartExperienceButton.setTitle("Restart", for: .normal)
    }

    private func buildResetButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(restartExperience), for: .touchUpInside)
        addSubview(button)

        // Add constraints for restartExperienceButton
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            button.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            button.heightAnchor.constraint(equalToConstant: 40),
            button.widthAnchor.constraint(equalToConstant: 40)
        ])

        return button
    }

    private func buildAddButton() -> UIButton {
        let button = UIButton(type: .system)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(chooseObject), for: .touchUpInside)
        addSubview(button)

        // Add constraints for addObjectButton
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 48),
            button.widthAnchor.constraint(equalToConstant: 48)
        ])

        return button
    }
}

// MARK: - Button Actions

extension FocusARSCNView {
    @objc func chooseObject() {
        // Implement your logic for choosing and loading a virtual object
    }

    @objc func restartExperience() {
        // Implement your logic for restarting the AR experience
    }
}
