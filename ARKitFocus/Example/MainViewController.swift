//
//  MainViewController.swift
//  ARKitFocus
//
//  Created by Matheus Gois on 03/01/24.
//

import ARKit
import SceneKit
import UIKit

final class MainViewController: UIViewController {

    private let sceneView = FocusARSCNView(object: Vase())

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        sceneView.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sceneView.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.viewWillDisappear(animated)
    }

    private func setupUI() {
        #if targetEnvironment(simulator)
        sceneView.backgroundColor = .black
        #endif

        view.addSubview(sceneView)
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
