//
//  TerrainNode.swift
//  SceneKit-Terrain
//
//  Created by Vivek Nagar on 9/6/18.
//  Copyright © 2018 Vivek Nagar. All rights reserved.
//

import SceneKit

struct MeshRange {
    var min:CGFloat
    var max:CGFloat
}
struct MeshCount {
    var one:Int
    var two:Int
}

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
        self.geometry = geometry
        self.name = "terrain"
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
        self.geometry = geometry
        self.name = "terrain"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func deformTerrainAt(_ location:SCNVector3, brushRadius:Double, intensity:Double) {
        print("Intensity is \(intensity)")
    }
    
    /*
    private func createGeometry1(material:SCNMaterial) -> SCNGeometry {
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
        
        for y in 0...Int(h-1) {
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
            let from = vertices[normalIndex]
            let to = vertices[normalIndex] + normals[normalIndex] * 4.0
            let node = Utils.createLine(from: from, to: to)
            self.addChildNode(node)
        }
        sources.append(SCNGeometrySource(normals: normals))
        
        let uvData = NSData(bytes: uvList, length: uvList.count * sizeOfVecFloat)
        let uvSource = SCNGeometrySource(data: uvData as Data, semantic: SCNGeometrySource.Semantic.texcoord, vectorCount: uvList.count, usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: sizeOfFloat, dataOffset: 0, dataStride: sizeOfVecFloat)
        sources.append(uvSource)
        
        let _terrainGeometry = SCNGeometry(sources: sources, elements: elements)
        _terrainGeometry.materials = [material]
        
        return _terrainGeometry
        
    }
    */
    
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
    
    private func createGeometry(material:SCNMaterial) -> SCNGeometry {
        let rangeOne = MeshRange(min: -CGFloat(width)/CGFloat(2), max: CGFloat(width)/CGFloat(2))
        let rangeTwo = MeshRange(min: -CGFloat(depth)/CGFloat(2), max: CGFloat(depth)/CGFloat(2))
        let textureRepeatCounts = MeshCount(one: 1, two: 1)
        
        let pointCount = width * depth;
        
        var vertices: Array<SCNVector3> = Array(repeating: SCNVector3Zero, count: pointCount)
        var normals: Array<SCNVector3> = Array(repeating: SCNVector3Zero, count: pointCount)
        var textures: Array<CGPoint> = Array(repeating: CGPoint.zero, count: pointCount)
        
        var numberOfIndices = (2*width)*(depth);
        if (depth%4==0) {
            numberOfIndices += 2;
        }
        
        var indices: Array<Int32> = Array(repeating: 0, count: numberOfIndices)
        
        //    The indices for a mesh
        //
        //    (1)━━━(2)━━━(3)━━━(4)
        //     ┃   ◥ ┃   ◥ ┃   ◥ ┃
        //     ┃  ╱  ┃  ╱  ┃  ╱  ┃
        //     ▼ ╱   ▼ ╱   ▼ ╱   ▼
        //    (4)━━━(5)━━━(6)━━━(7)⟳  nr 7 twice
        //     ┃ ◤   ┃ ◤   ┃ ◤   ┃
        //     ┃  ╲  ┃  ╲  ┃  ╲  ┃
        //     ┃   ╲ ┃   ╲ ┃   ╲ ┃
        //  ⟳(8)━━━(9)━━━(10)━━(11)   nr 8 twice
        //     ┃   ◥ ┃   ◥ ┃   ◥ ┃
        //     ┃  ╱  ┃  ╱  ┃  ╱  ┃
        //     ▼ ╱   ▼ ╱   ▼ ╱   ▼
        //    (12)━━(13)━━(14)━━(15)
        
        var lastIndex = 0;
        for row in 0..<(width-1) {
            let isEven = row%2 == 0;
            for col in 0..<depth {
                
                if (isEven) {
                    indices[lastIndex] = Int32(row*width + col)
                    lastIndex = lastIndex + 1
                    indices[lastIndex] = Int32((row+1)*width + col)
                    if (col == depth-1) {
                        lastIndex = lastIndex + 1
                        indices[lastIndex] = Int32((row+1)*width + col)
                    }
                } else {
                    indices[lastIndex] = Int32(row*width + (depth-1-col))
                    lastIndex = lastIndex + 1
                    indices[lastIndex] = Int32((row+1)*width + (depth-1-col))
                    if (col == depth-1) {
                        lastIndex = lastIndex + 1
                        indices[lastIndex] = Int32((row+1)*width + (depth-1-col))
                    }
                }
                lastIndex = lastIndex + 1
            }
        }
        
        // Generate the mesh by calculating the vector, normal
        // and texture coordinate for each x,z pair.
        
        for row in 0..<width {
            for col in 0..<depth {
                
                let one = CGFloat(CGFloat(col)/CGFloat(width-1)) * CGFloat(rangeOne.max - rangeOne.min) + CGFloat(rangeOne.min)
                let two = CGFloat(CGFloat(row)/CGFloat(depth-1)) * CGFloat(rangeTwo.max - rangeTwo.min) + CGFloat(rangeTwo.min)
                print("one is \(one), two is \(two)")
                
                let value = self.vectorForFunction(one:one, two:two, offset1:rangeOne.min, offset2:rangeTwo.min)
                
                vertices[col + row*depth] = value;
                
                //let delta = CGFloat(0.001)
                let delta = CGFloat(1.0)
                let dx = value - self.vectorForFunction(one:one+delta, two:two, offset1:rangeOne.min, offset2:rangeTwo.min)
                
                let dz = value - self.vectorForFunction(one:one, two:two+delta, offset1:rangeOne.min, offset2:rangeTwo.min)
                
                
                let crossProductVector = dz.cross(vector: dx)
                normals[col + row*depth] = crossProductVector.normalize()
                
                
                textures[col + row*depth] = CGPoint(x:CGFloat(col)/CGFloat(width)*CGFloat(textureRepeatCounts.one),
                                                    y:CGFloat(row)/CGFloat(depth)*CGFloat(textureRepeatCounts.two))
                
            }
        }
        
        // Create geometry sources for the generated data
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals:normals)
        let textureSource = SCNGeometrySource(textureCoordinates:textures)
        
        // Configure the indices that was to be interpreted as a
        // triangle strip using
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangleStrip)
        
        // Create geometry from these sources
        let geometry = SCNGeometry(sources:[vertexSource, normalSource, textureSource] , elements: [element])
        
        // Since the builder exposes a geometry with repeating texture
        // coordinates it is configured with a repeating material
        
        geometry.materials = [material];
        
        /*
         for normalIndex in 0...normals.count-1 {
         let from = vertices[normalIndex]
         let to = vertices[normalIndex] + normals[normalIndex] * 1.0
         let node = Utils.createLine(from: from, to: to)
         self.addChildNode(node)
         }
         */
        
        return geometry;
        
    }

    private func vectorForFunction(one:CGFloat, two:CGFloat, offset1:CGFloat, offset2:CGFloat) -> SCNVector3
    {
        let x = one
        let y = CGFloat(heightFromMap(x: Int(one-offset1), y: Int(two-offset2)))
        let z = two
        return SCNVector3Make(x, y, z)
    }
}
