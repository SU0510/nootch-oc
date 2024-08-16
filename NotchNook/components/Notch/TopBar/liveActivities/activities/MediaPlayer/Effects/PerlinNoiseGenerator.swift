//
//  PerlinNoiseGenerator.swift
//  NotchNook
//
//  Created by Lori Montenegro on 14/08/24.
//

import Foundation

/// A generator for Perlin noise, which creates smooth, natural-looking random variations.
///
/// Perlin noise is used to generate unpredictable yet smooth movement patterns. It produces
/// gradual, continuous changes in values, making it ideal for creating natural-looking
/// randomness in various applications, including movement algorithms.
class PerlinNoiseGenerator {
    private var permutation: [Int]
    
    init() {
        permutation = Array(0...255)
        permutation.shuffle()
        permutation += permutation
    }
    
    /// Generates a Perlin noise value for the given 3D coordinates.
    ///
    /// This method produces a pseudo-random value that smoothly transitions between
    /// neighboring coordinates. When used for movement, it creates a more organic,
    /// less predictable pattern compared to simple random number generation.
    ///
    /// - Returns: A noise value between -1 and 1.
    func noise(x: Double, y: Double, z: Double) -> Double {
        let X = Int(floor(x)) & 255
        let Y = Int(floor(y)) & 255
        let Z = Int(floor(z)) & 255
        
        let xf = x - floor(x)
        let yf = y - floor(y)
        let zf = z - floor(z)
        
        let u = fade(xf)
        let v = fade(yf)
        let w = fade(zf)
        
        let A  = permutation[X] + Y
        let AA = permutation[A] + Z
        let AB = permutation[A + 1] + Z
        let B  = permutation[X + 1] + Y
        let BA = permutation[B] + Z
        let BB = permutation[B + 1] + Z
        
        return lerp(w, lerp(v, lerp(u, grad(permutation[AA], xf, yf, zf),
                                    grad(permutation[BA], xf - 1, yf, zf)),
                            lerp(u, grad(permutation[AB], xf, yf - 1, zf),
                                 grad(permutation[BB], xf - 1, yf - 1, zf))),
                    lerp(v, lerp(u, grad(permutation[AA + 1], xf, yf, zf - 1),
                                 grad(permutation[BA + 1], xf - 1, yf, zf - 1)),
                         lerp(u, grad(permutation[AB + 1], xf, yf - 1, zf - 1),
                              grad(permutation[BB + 1], xf - 1, yf - 1, zf - 1))))
    }
    
    private func fade(_ t: Double) -> Double {
        return t * t * t * (t * (t * 6 - 15) + 10)
    }
    
    private func lerp(_ t: Double, _ a: Double, _ b: Double) -> Double {
        return a + t * (b - a)
    }
    
    private func grad(_ hash: Int, _ x: Double, _ y: Double, _ z: Double) -> Double {
        let h = hash & 15
        let u = h < 8 ? x : y
        let v = h < 4 ? y : (h == 12 || h == 14 ? x : z)
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
}
