//
//  TerrainNode.swift
//  SceneKit-Terrain
//
//  Created by Vivek Nagar on 9/6/18.
//  Copyright © 2018 Vivek Nagar. All rights reserved.
//

import SceneKit

enum TerrainType: Int {
    case heightmap = 0
    case perlinnoise = 1
}
typealias TerrainFormula = ((Int32, Int32) -> (Double))

class TerrainNode : SCNNode {
    var pixels = [[Pixel]]()
    var formula: TerrainFormula?

    let type:TerrainType
    let width:Int
    let depth:Int
    
    init(width: Int, depth: Int, material:SCNMaterial) {
        type = .perlinnoise
        self.width = width
        self.depth = depth
        let generator = PerlinNoiseGenerator(seed: nil)
        self.formula = {(x: Int32, y: Int32) in
            return generator.valueFor(x: x, y: y)
        }
        super.init()
        
        let geometry = createGeometry(material:material)
        let terrainNode = SCNNode(geometry: geometry)
        terrainNode.geometry = geometry
        terrainNode.name = "terrain"
        
        self.addChildNode(terrainNode)
    }
    
    init(heightMap: String, material:SCNMaterial) {
        
        type = .heightmap

        if let imagePath = Bundle.main.path(forResource:heightMap, ofType:nil) {
            guard let image = GameImage(contentsOfFile: imagePath) else {
                fatalError("Cannot read heightmap data")
            }
            self.width = Int(image.size.width)
            self.depth = Int(image.size.height)
            pixels = image.pixelData()
        } else {
            fatalError("Cannot read heightmap")
        }
        
        super.init()

        let geometry = createGeometry(material:material)
        let terrainNode = SCNNode(geometry: geometry)
        terrainNode.geometry = geometry
        terrainNode.name = "terrain"

        self.addChildNode(terrainNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func deformTerrainAt(_ location:SCNVector3, brushRadius:Double, intensity:Double) {
        print("Intensity is \(intensity)")
    }
    
    private func createGeometry(material:SCNMaterial) -> SCNGeometry {
        let cint: CInt = 0
        let sizeOfCInt = MemoryLayout.size(ofValue: cint)
        let float: Float = 0.0
        let sizeOfFloat = MemoryLayout.size(ofValue: float)
        let vec2: vector_float2 = vector2(0, 0)
        let sizeOfVecFloat = MemoryLayout.size(ofValue: vec2)
        
        let w: CGFloat = CGFloat(width)
        let h: CGFloat = CGFloat(depth)
        let scale: Double = Double(1.0)
        
        var sources = [SCNGeometrySource]()
        var elements = [SCNGeometryElement]()
        
        let maxElements: Int = width * depth * 4
        var vertices = [SCNVector3](repeating:SCNVector3Zero, count:maxElements)
        var normals = [SCNVector3](repeating:SCNVector3Zero, count:maxElements)
        var uvList: [vector_float2] = []
        
        var vertexCount = 0
        let factor: CGFloat = 0.5
        
        for y in 0...Int(h-2) {
            for x in 0...Int(w-1) {
                let topLeftZ = heightFromMap(x: Int(x), y: Int(y+1)) / CGFloat(scale)
                let topRightZ = heightFromMap(x: Int(x+1), y: Int(y+1)) / CGFloat(scale)
                let bottomLeftZ = heightFromMap(x: Int(x), y: Int(y)) / CGFloat(scale)
                let bottomRightZ = heightFromMap(x: Int(x+1), y: Int(y)) / CGFloat(scale)
                //print("\(topLeftZ), \(topRightZ), \(bottomLeftZ), \(bottomRightZ)")
                
                let topLeft = SCNVector3Make(CGFloat(x)-CGFloat(factor), CGFloat(topLeftZ), CGFloat(y)+CGFloat(factor))
                let topRight = SCNVector3Make(CGFloat(x)+CGFloat(factor), CGFloat(topRightZ), CGFloat(y)+CGFloat(factor))
                let bottomLeft = SCNVector3Make(CGFloat(x)-CGFloat(factor), CGFloat(bottomLeftZ), CGFloat(y)-CGFloat(factor))
                let bottomRight = SCNVector3Make(CGFloat(x)+CGFloat(factor), CGFloat(bottomRightZ), CGFloat(y)-CGFloat(factor))
                
                vertices[vertexCount] = bottomLeft
                vertices[vertexCount+1] = topLeft
                vertices[vertexCount+2] = topRight
                vertices[vertexCount+3] = bottomRight
                
                let xf = CGFloat(x)
                let yf = CGFloat(y)
                
                uvList.append(vector_float2(Float(xf/w), Float(yf/h)))
                uvList.append(vector_float2(Float(xf/w), Float((yf+factor)/h)))
                uvList.append(vector_float2(Float((xf+factor)/w), Float((yf+factor)/h)))
                uvList.append(vector_float2(Float((xf+factor)/w), Float(yf/h)))
                
                vertexCount += 4
            }
        }
        
        let source = SCNGeometrySource(vertices: vertices)
        sources.append(source)
        
        let geometryData = NSMutableData()
        
        var geometry: CInt = 0
        while (geometry < CInt(vertexCount)) {
            let bytes: [CInt] = [geometry, geometry+2, geometry+3, geometry, geometry+1, geometry+2]
            geometryData.append(bytes, length: sizeOfCInt*6)
            geometry += 4
        }
        
        let element = SCNGeometryElement(data: geometryData as Data, primitiveType: .triangles, primitiveCount: vertexCount/2, bytesPerIndex: sizeOfCInt)
        elements.append(element)
        
        for normalIndex in 0...vertexCount-1 {
            normals[normalIndex] = SCNVector3Make(0, 0, -1)
        }
        sources.append(SCNGeometrySource(normals: normals))
        
        let uvData = NSData(bytes: uvList, length: uvList.count * sizeOfVecFloat)
        let uvSource = SCNGeometrySource(data: uvData as Data, semantic: SCNGeometrySource.Semantic.texcoord, vectorCount: uvList.count, usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: sizeOfFloat, dataOffset: 0, dataStride: sizeOfVecFloat)
        sources.append(uvSource)
        
        let _terrainGeometry = SCNGeometry(sources: sources, elements: elements)
        _terrainGeometry.materials = [material]
        
        return _terrainGeometry
        
    }
    
    private func heightFromMap(x:Int, y:Int) -> CGFloat {
        if(type == .heightmap) {
            //print("Getting height of pixel:\(x),\(y)")
            if(x<0 || y < 0 || x>=width || y>=depth) {
                return 0.0
            }
            return pixels[x][y].intensity * 50.0
        } else {
            // Perlin Noise
            if (formula == nil) {
                return 0.0
            }
            
            let val = formula!(Int32(x), Int32(y))
            return CGFloat(val/32.0)
        }
    }

}
