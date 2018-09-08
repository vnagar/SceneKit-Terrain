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
    var _meshVertices:[SCNVector3] = [SCNVector3]()
    var _indices:[Int32] = [Int32]()
    var _textures:[CGPoint] = [CGPoint]()
    var _normals:[SCNVector3] = [SCNVector3]()
    var _material:SCNMaterial
    
    var pixels = [[Pixel]]()
    var formula: TerrainFormula?

    let type:TerrainType
    let width:Int
    let depth:Int
    
    init(width: Int, depth: Int, material:SCNMaterial) {
        type = .perlinnoise
        _material = material
        self.width = width
        self.depth = depth
        let generator = PerlinNoiseGenerator(seed: nil)
        self.formula = {(x: Int32, y: Int32) in
            return generator.valueFor(x: x, y: y)
        }
        super.init()
        
        self.geometry = createGeometry(material:material)
        self.name = "terrain"
    }
    
    init(heightMap: String, material:SCNMaterial) {
        type = .heightmap
        _material = material
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

        self.geometry = createGeometry(material:material)
        self.name = "terrain"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func deformTerrainAt(_ location:SCNVector3, brushRadius:Double, intensity:Double) {
        let rangeOne = MeshRange(min: -CGFloat(width)/CGFloat(2), max: CGFloat(width)/CGFloat(2))
        let rangeTwo = MeshRange(min: -CGFloat(depth)/CGFloat(2), max: CGFloat(depth)/CGFloat(2))
        let radiusInIndices = brushRadius * Double(width)
        
        let vx = Double(location.x)
        let vy = Double(location.z)
        
        for y in 0..<depth {
            for x in 0..<width {
                let one = CGFloat(CGFloat(x)/CGFloat(width-1)) * CGFloat(rangeOne.max - rangeOne.min) + CGFloat(rangeOne.min)
                let two = CGFloat(CGFloat(y)/CGFloat(depth-1)) * CGFloat(rangeTwo.max - rangeTwo.min) + CGFloat(rangeTwo.min)
                
                let xDelta = vx - Double(one)
                let yDelta = vy - Double(two)
                let dist = sqrt((xDelta * xDelta) + (yDelta * yDelta));
                
                if (dist < radiusInIndices)
                {
                    let index = (y * width) + x;
                    
                    var relativeIntensity = 1.0 - (dist / radiusInIndices)
                    
                    relativeIntensity = sin(relativeIntensity * Double.pi/2)
                    relativeIntensity *= intensity;
                    
                    _meshVertices[index].y += CGFloat(relativeIntensity)
                }
            }
        }
        self.geometry = deformGeometry(material:_material)
    }
    
    private func heightFromMap(x:Int, y:Int) -> CGFloat {
        if(type == .heightmap) {
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
                
                let value = self.vectorForFunction(one:one, two:two, offset1:rangeOne.min, offset2:rangeTwo.min)
                
                vertices[col + row*depth] = value
                
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
        
        //Save the geometry for future use.
        _meshVertices = vertices
        _indices = indices
        _textures = textures
        _normals = normals
        
        geometry.materials = [material];
        
        return geometry;
    }

    private func vectorForFunction(one:CGFloat, two:CGFloat, offset1:CGFloat, offset2:CGFloat) -> SCNVector3 {
        let x = one
        let y = CGFloat(heightFromMap(x: Int(one-offset1), y: Int(two-offset2)))
        let z = two
        return SCNVector3Make(x, y, z)
    }
    
    private func deformGeometry(material:SCNMaterial) -> SCNGeometry {
        // TODO: Recompute normals??
        let vertexSource = SCNGeometrySource(vertices: _meshVertices)
        let normalSource = SCNGeometrySource(normals:_normals)
        let textureSource = SCNGeometrySource(textureCoordinates:_textures)
        
        // Configure the indices that was to be interpreted as a triangle strip using
        let element = SCNGeometryElement(indices: _indices, primitiveType: .triangleStrip)
        
        // Create geometry from these sources
        let geometry = SCNGeometry(sources:[vertexSource, normalSource, textureSource] , elements: [element])
        geometry.materials = [material];
        
        return geometry;
    }
}
