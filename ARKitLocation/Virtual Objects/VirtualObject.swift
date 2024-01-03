//
//  VirtualObject.swift
//  ARKitLocation
//
//  Created by Matheus Gois on 03/01/24.
//

import ARKit
import UIKit

class VirtualObject: SCNNode {
    static let ROOT_NAME = "Virtual object root node"
    var fileExtension = ""
    var thumbImage: UIImage!
    var title = ""
    var modelName = ""
    var modelLoaded = false
    var id: Int!

    var viewController: MainViewController?

    override init() {
        super.init()
        self.name = VirtualObject.ROOT_NAME
    }

    init(modelName: String, fileExtension: String, thumbImageFilename: String, title: String) {
        super.init()
        self.id = VirtualObjectsManager.shared.generateUid()
        self.name = VirtualObject.ROOT_NAME
        self.modelName = modelName
        self.fileExtension = fileExtension
        self.thumbImage = UIImage(named: thumbImageFilename)
        self.title = title
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadModel() {
        guard let virtualObjectScene = SCNScene(
            named: "\(modelName).\(fileExtension)",
            inDirectory: "Models.scnassets/\(modelName)"
        ) else {
            return
        }

        let wrapperNode = SCNNode()

        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            child.movabilityHint = .movable
            wrapperNode.addChildNode(child)
        }
        addChildNode(wrapperNode)

        modelLoaded = true
    }

    func unloadModel() {
        for child in childNodes {
            child.removeFromParentNode()
        }

        modelLoaded = false
    }

    func translateBasedOnScreenPos(_ pos: CGPoint, instantly: Bool, infinitePlane: Bool) {
        guard let controller = viewController else {
            return
        }
        let result = controller.worldPositionFromScreenPosition(
            pos,
            objectPos: position,
            infinitePlane: infinitePlane
        )

        controller.moveVirtualObjectToPosition(
            result.position,
            instantly,
            !result.hitAPlane
        )
    }
}

extension VirtualObject {

    static func isNodePartOfVirtualObject(_ node: SCNNode) -> Bool {
        if node.name == VirtualObject.ROOT_NAME {
            return true
        }

        if node.parent != nil {
            return isNodePartOfVirtualObject(node.parent!)
        }

        return false
    }
}

// MARK: - Protocols for Virtual Objects

protocol ReactsToScale {
    func reactToScale()
}

extension SCNNode {

    func reactsToScale() -> ReactsToScale? {
        if let canReact = self as? ReactsToScale {
            return canReact
        }

        if parent != nil {
            return parent!.reactsToScale()
        }

        return nil
    }
}
