//
//  VirtualObject.swift
//  ARKitFocus
//
//  Created by Matheus Gois on 03/01/24.
//

import ARKit
import UIKit
import SceneKit

protocol VirtualObjectProtocol: AnyObject {
    func moveVirtualObjectToPosition(
        _ pos: SCNVector3?,
        _ instantly: Bool,
        _ filterPosition: Bool
    )

    func worldPositionFromScreenPosition(
        _ position: CGPoint,
        objectPos: SCNVector3?,
        infinitePlane: Bool
    ) -> (
        position: SCNVector3?,
        planeAnchor: ARPlaneAnchor?,
        hitAPlane: Bool
    )
}

class VirtualObject: SCNNode {

    static let ROOT_NAME = "Virtual object root node"

    var fileExtension = ""
    var modelName = ""

    weak var delegate: VirtualObjectProtocol?

    override init() {
        super.init()
        self.name = VirtualObject.ROOT_NAME
    }

    init(modelName: String, fileExtension: String) {
        super.init()
        self.name = VirtualObject.ROOT_NAME
        self.modelName = modelName
        self.fileExtension = fileExtension
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadModel() {
        guard let virtualObjectScene = SCNScene(named: "\(modelName).\(fileExtension)",
                                                inDirectory: "Models.scnassets/\(modelName)") else {
            return
        }

        let wrapperNode = SCNNode()

        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            child.movabilityHint = .movable
            wrapperNode.addChildNode(child)
        }
        addChildNode(wrapperNode)
    }

    func unloadModel() {
        removeAllChildren()
    }

    func translateBasedOnScreenPos(_ pos: CGPoint, instantly: Bool, infinitePlane: Bool) {
        guard let delegate else { return }
        let result = delegate.worldPositionFromScreenPosition(
            pos,
            objectPos: position,
            infinitePlane: infinitePlane
        )

        delegate.moveVirtualObjectToPosition(
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

        if let parent = node.parent {
            return isNodePartOfVirtualObject(parent)
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

        if let parent = parent {
            return parent.reactsToScale()
        }

        return nil
    }
}
