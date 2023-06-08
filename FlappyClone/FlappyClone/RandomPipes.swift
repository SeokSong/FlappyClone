//
//  RandomPipes.swift
//  FlappyClone
//
//  Created by Seok Song on 6/7/23.
//

import Foundation
import CoreGraphics

public extension CGFloat{
    
    public static func random() -> CGFloat{
        
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    public static func random(min min: CGFloat, max: CGFloat) -> CGFloat{
        return CGFloat.random() * (max - min) + min //prevents negative value
    }
    
}
