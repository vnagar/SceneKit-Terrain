//
//  GameViewController.swift
//  SceneKit-Terrain
//
//  Created by Vivek Nagar on 9/6/18.
//  Copyright © 2018 Vivek Nagar. All rights reserved.
//

import SceneKit
import SpriteKit
import QuartzCore

class GameViewController: NSViewController, GameInputDelegate {
        
    @IBOutlet var gameView: GameView!
    let scene = SCNScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // retrieve the SCNView
        let scnView = self.view as! GameView
        scnView.eventsDelegate = self
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        //scnView.debugOptions = [.showWireframe]
        scnView.backgroundColor = NSColor.black
        
        // configure the scene
        scene.background.contents = "art.scnassets/textures/img_skybox.jpg"
        scnView.scene = scene

        self.createOverlayScene()
        self.configureCameraAndLighting()
        self.addTerrain(type:.heightmap)
    }
    
    private func addTerrain(type:TerrainType) {
        let material = SCNMaterial()
        material.diffuse.contents = "art.scnassets/textures/SeamlessGrass.jpg"
        material.isDoubleSided = false
        material.isLitPerPixel = true
        material.diffuse.magnificationFilter = .none
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(CGFloat(16), CGFloat(16), 1)
        material.diffuse.intensity = 1.0
        
        var terrain:TerrainNode?
        if(type == .heightmap) {
            terrain = TerrainNode(heightMap: "art.scnassets/textures/heightmap.png", material:material)
        } else {
            terrain = TerrainNode(width: 256, depth: 256, material: material)
        }
        
        if let terrainMaterial = terrain?.geometry?.firstMaterial {
            let dirt_texture = SCNMaterialProperty(contents: "art.scnassets/textures/Cliff.jpg")
            let grass_texture = SCNMaterialProperty(contents:"art.scnassets/textures/SeamlessGrass.jpg")
            
            terrainMaterial.setValue(grass_texture, forKeyPath: "grassTexture")
            terrainMaterial.setValue(dirt_texture, forKeyPath: "dirtTexture")
            
            let res = Bundle.main.path(forResource: "terrain", ofType: "shader", inDirectory:"art.scnassets/shaders")
            let surfaceModifier = try? String(contentsOfFile: res!)
            terrainMaterial.shaderModifiers = [SCNShaderModifierEntryPoint.surface: surfaceModifier!]
        }
        
        if let terrain = terrain {
            terrain.position = SCNVector3Make(0, 0, 0)
            scene.rootNode.addChildNode(terrain)
        }
    }
    
    private func configureCameraAndLighting() {
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera!.zFar = 400
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 16, y: 8, z: 16)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 16, y: 10, z: 16)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
    }
    
    private func createOverlayScene() {
        //setup overlay
        let scnView = self.view as! SCNView
        let overlayScene = SKScene(size: scnView.bounds.size);
        scnView.overlaySKScene = overlayScene;
        
        var node = SKSpriteNode(imageNamed:"art.scnassets/textures/video_camera.png")
        node.position = CGPoint(x: overlayScene.size.width * 0.9, y: overlayScene.size.height*0.9)
        node.name = "cameraNode"
        node.xScale = 0.5
        node.yScale = 0.5
        overlayScene.addChild(node)
        
        node = SKSpriteNode(imageNamed:"art.scnassets/textures/tool.png")
        node.position = CGPoint(x: overlayScene.size.width * 0.8, y: overlayScene.size.height*0.9)
        node.name = "toolNode"
        overlayScene.addChild(node)
    }
    
    func handleMouseDown(with theEvent: NSEvent) {
        guard let view = gameView else {
            fatalError("Scene not created")
        }
        
        guard let overlayScene = view.overlaySKScene else {
            print("No overlay scene")
            return
        }
        
        let location:CGPoint = theEvent.location(in: overlayScene)
        let node:SKNode = overlayScene.atPoint(location)
        if let name = node.name { // Check if node name is not nil
            if(name == "cameraNode") {
                print("Clicked camera node")
                gameView.allowsCameraControl = true
                return
            }
            else if(name == "toolNode") {
                print("Clicked tool node")
                gameView.allowsCameraControl = false
                return
            }
        }
        
        if (!gameView.allowsCameraControl) {
            self.applyDeformToMesh(theEvent)
        }
    }
    
    func handleMouseUp(with theEvent: NSEvent) {
        
    }
    
    func handleMouseDragged(with theEvent: NSEvent) {
        if (!gameView.allowsCameraControl) {
            self.applyDeformToMesh(theEvent)
        }
    }
    
    func handleKeyDown(with: NSEvent) {
        
    }
    
    func handleKeyUp(with: NSEvent) {
        
    }
    
    func applyDeformToMesh(_ theEvent:NSEvent) {
        var point = theEvent.locationInWindow
        point = gameView.convert(point, from: nil)
        
        let hitTest = gameView.hitTest(point, options: nil)
        if !hitTest.isEmpty {
            let node = hitTest[0].node
            if(node.name == "terrain") {
                let terrain = node as! TerrainNode
                let val = UInt32(theEvent.modifierFlags.rawValue) & UInt32(NSEvent.ModifierFlags.option.rawValue)
                terrain.deformTerrainAt(hitTest[0].localCoordinates, brushRadius:0.10, intensity:0.1 * (val > 0 ? -1.0 : 1.0))

            }
        }
    }
    
}
