//
//  Utils.swift
//  Terrain
//
//  Created by Vivek Nagar on 10/7/16.
//  Copyright © 2016 Vivek Nagar. All rights reserved.
//

import SceneKit

#if os(iOS)
    typealias TerrainColor=UIColor
    typealias GameImage=UIImage
#elseif os(OSX)
    typealias TerrainColor=NSColor
    typealias GameImage=NSImage
#endif
    
enum KeyboardDirection : UInt16 {
    case left   = 123
    case right  = 124
    case down   = 125
    case up     = 126
    
    var vector : float2 {
        switch self {
        case .up:    return float2( 0, 1)
        case .down:  return float2( 0, -1)
        case .left:  return float2(1,  0)
        case .right: return float2(-1,  0)
        }
    }
}

struct Pixel {
    var r: Float
    var g: Float
    var b: Float
    var a: Float
    var row: Int
    var col: Int
    
    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8, row: Int, col: Int) {
        self.r = Float(r)
        self.g = Float(g)
        self.b = Float(b)
        self.a = Float(a)
        self.row = row
        self.col = col
    }
    
    var color: TerrainColor {
        return TerrainColor(red: CGFloat(r/255.0), green: CGFloat(g/255.0), blue: CGFloat(b/255.0), alpha: CGFloat(a/255.0))
    }
    
    var description: String {
        return "RGBA(\(r), \(g), \(b), \(a))"
    }
    
    var intensity:CGFloat {
        return CGFloat(r)/255.0
    }
}

#if os(OSX)
    extension NSImage {
        func pixelData() -> [[Pixel]] {
            let bmp = self.representations[0] as! NSBitmapImageRep
            var data: UnsafeMutablePointer<UInt8> = bmp.bitmapData!
            var r, g, b, a: UInt8
            var pixels: [[Pixel]] = Array(repeating: Array(repeating: Pixel(r:0, g:0, b:0, a:0, row:0, col:0), count: bmp.pixelsHigh+1), count: bmp.pixelsWide+1)
            
            for row in 0..<bmp.pixelsHigh {
                for col in 0..<bmp.pixelsWide {
                    r = data.pointee
                    data = data.advanced(by:1)
                    g = data.pointee
                    data = data.advanced(by:1)
                    b = data.pointee
                    data = data.advanced(by:1)
                    a = data.pointee
                    data = data.advanced(by:1)
                    pixels[row][col] = Pixel(r: r, g: g, b: b, a: a, row:row, col:col)
                }
            }
            return pixels
        }
    }

#else
    extension UIImage {
        func pixelData() -> [[Pixel]] {
            guard let pixelData = self.cgImage!.dataProvider!.data else {
                print("ERROR reading pixel data")
                return [[Pixel]]()
            }
            let data = CFDataGetBytePtr(pixelData)!
            var pixels: [[Pixel]] = Array(repeating: Array(repeating: Pixel(r:0, g:0, b:0, a:0, row:0, col:0), count: Int(self.size.height)), count: Int(self.size.width))
            
            for row in 0..<Int(self.size.height) {
                for col in 0..<Int(self.size.width) {
                    let index = Int(self.size.width) * row + col
                    let expectedLengthA = Int(self.size.width * self.size.height)
                    let expectedLengthRGB = 3 * expectedLengthA
                    let expectedLengthRGBA = 4 * expectedLengthA
                    let numBytes = CFDataGetLength(pixelData)
                    switch numBytes {
                    case expectedLengthA:
                        pixels[row][col] = Pixel(r: 0, g: 0, b: 0, a:UInt8(data[index]), row:row, col:col)
                    case expectedLengthRGB:
                        pixels[row][col] = Pixel(r:UInt8(data[3*index]), g: UInt8(data[3*index+1]), b: UInt8(data[3*index+2]), a: 255, row:row, col:col)
                    case expectedLengthRGBA:
                        //This should be the right one
                        pixels[row][col] = Pixel(r: UInt8(data[4*index]), g: UInt8(data[4*index+1]), b:UInt8(data[4*index+2]) , a: UInt8(data[4*index+3]), row:row, col:col)
                        
                    default:
                        pixels[row][col] = Pixel(r: 0, g: 0, b: 0, a: 0, row:row, col:col)
                    }
                }
            }
            return pixels
        }
    }
#endif

class Utils {
    static func crossProduct(a:SCNVector3, b:SCNVector3) -> SCNVector3 {
        return SCNVector3Make(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x);
    }
    
    static func vectorSubtract(a:SCNVector3, b:SCNVector3) -> SCNVector3 {
        return SCNVector3Make(a.x-b.x, a.y-b.y, a.z-b.z);
    }

    class func createLine(from:SCNVector3, to:SCNVector3, color:NSColor=NSColor.red) -> SCNNode {
        let data = [from, to]
        let indices:[Int32] = [0, 1]
        
        let indexData = NSData(bytes: indices, length: indices.count * MemoryLayout<Int32>.size)
        let vertexSource = SCNGeometrySource(vertices: data)
        let element = SCNGeometryElement(data: indexData as Data,
                                         primitiveType: SCNGeometryPrimitiveType.line,
                                         primitiveCount: 1,
                                         bytesPerIndex: MemoryLayout<Int32>.size)
        
        let geo = SCNGeometry(sources: [vertexSource], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = color
        geo.firstMaterial = material
        geo.firstMaterial!.isDoubleSided = true
        geo.firstMaterial!.diffuse.contents = color
        return SCNNode(geometry: geo)
    }
}

extension SCNVector3
{
    /* Cast to float3 */
    init(_ floatValue:float3) {
        self.init()
        self.x = CGFloat(floatValue.x)
        self.y = CGFloat(floatValue.y)
        self.z = CGFloat(floatValue.z)
    }
    
    /* Length of vector */
    func length() -> Float {
        return sqrtf(Float(x*x + y*y + z*z))
    }
    
    func normalize() -> SCNVector3 {
        let len = sqrt(pow(self.x, 2) + pow(self.y, 2) + pow(self.z, 2))
        
        return SCNVector3Make(self.x/len, self.y/len, self.z/len)
    }
    
    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0 and returns
     * the result as a new SCNVector3.
     */
    func normalized() -> SCNVector3 {
        return SCNVector3(Float(self.x)/length(), Float(self.y)/length(), Float(self.z)/length())
    }
    
    /**
     * Negates the vector described by SCNVector3 and returns
     * the result as a new SCNVector3.
     */
    func negate() -> SCNVector3 {
        return self * -1
    }
    
    /**
     * Negates the vector described by SCNVector3
     */
    mutating func negated() -> SCNVector3 {
        self = negate()
        return self
    }
    
    /**
     * Calculates the distance between two SCNVector3. Pythagoras!
     */
    func distance(vector: SCNVector3) -> Float {
        return (self - vector).length()
    }
    
    /**
     * Calculates the dot product between two SCNVector3.
     */
    func dot(vector: SCNVector3) -> Float {
        return Float(x * vector.x + y * vector.y + z * vector.z)
    }
    
    /**
     * Calculates the cross product between two SCNVector3.
     */
    func cross(vector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(y * vector.z - z * vector.y, z * vector.x - x * vector.z, x * vector.y - y * vector.x)
    }
    
    func perpendicular() -> SCNVector3 {
        return SCNVector3Make(-z, y, x)
    }
}

/**
 * Adds two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

/**
 * Increments a SCNVector3 with the value of another.
 */
func += ( left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

/**
 * Subtracts two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

/**
 * Decrements a SCNVector3 with the value of another.
 */
func -= ( left: inout SCNVector3, right: SCNVector3) {
    left = left - right
}

/**
 * Multiplies two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
}

/**
 * Multiplies a SCNVector3 with another.
 */
func *= ( left: inout SCNVector3, right: SCNVector3) {
    left = left * right
}

/**
 * Multiplies the x, y and z fields of a SCNVector3 with the same scalar value and
 * returns the result as a new SCNVector3.
 */
func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x * CGFloat(scalar), vector.y * CGFloat(scalar), vector.z * CGFloat(scalar))
}

/**
 * Multiplies the x and y fields of a SCNVector3 with the same scalar value.
 */
func *= ( vector: inout SCNVector3, scalar: Float) {
    vector = vector * scalar
}

/**
 * Divides two SCNVector3 vectors abd returns the result as a new SCNVector3
 */
func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x / right.x, left.y / right.y, left.z / right.z)
}

/**
 * Divides a SCNVector3 by another.
 */
func /= ( left: inout SCNVector3, right: SCNVector3) {
    left = left / right
}

/**
 * Divides the x, y and z fields of a SCNVector3 by the same scalar value and
 * returns the result as a new SCNVector3.
 */
func / (vector: SCNVector3, scalar: CGFloat) -> SCNVector3 {
    return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
}


/**
 * Negate a vector
 */
func SCNVector3Negate(vector: SCNVector3) -> SCNVector3 {
    return vector * -1
}

/**
 * Returns the length (magnitude) of the vector described by the SCNVector3
 */
func SCNVector3Length(vector: SCNVector3) -> Float
{
    return sqrtf(Float(vector.x*vector.x + vector.y*vector.y + vector.z*vector.z))
}

/**
 * Returns the distance between two SCNVector3 vectors
 */
func SCNVector3Distance(vectorStart: SCNVector3, vectorEnd: SCNVector3) -> Float {
    return SCNVector3Length(vector: vectorEnd - vectorStart)
}


/**
 * Calculates the dot product between two SCNVector3 vectors
 */
func SCNVector3DotProduct(left: SCNVector3, right: SCNVector3) -> Float {
    return Float(left.x * right.x + left.y * right.y + left.z * right.z)
}

/**
 * Calculates the cross product between two SCNVector3 vectors
 */
func SCNVector3CrossProduct(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.y * right.z - left.z * right.y, left.z * right.x - left.x * right.z, left.x * right.y - left.y * right.x)
}



