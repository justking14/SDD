//
//  Customer.swift
//  KookieKiosk-Swift
//
//  Created by Barbara Reichart on 14/07/14.
//  Copyright (c) 2014 Barbara Reichart. All rights reserved.
//

import SpriteKit

class Customer : SKNode {
    
    let type: String
    let flavor: String
    
    var hasBeenServed = false
    
    init(type: String, flavor: String) {
        self.type = type
        self.flavor = flavor
        super.init()
        
        let customerNode = SKNode()
        let customerFile = String(format: "customer_%i", arc4random() % 3 + 1)
        let customerSprite = SKSpriteNode(imageNamed: customerFile)
        let bubble = SKSpriteNode(imageNamed: "thought_bubble")
        
        let width = max(customerSprite.size.width, bubble.size.width)
        let height = customerSprite.size.height + bubble.size.height
        
        customerSprite.position = CGPoint(x: (width - customerSprite.size.width) / 2, y: -(height - customerSprite.size.height) / 2)
        customerSprite.zPosition = CGFloat(ZPosition.HUDBackground.rawValue)
        bubble.position = CGPoint(x: (width - bubble.size.width) / 2, y: (height - bubble.size.height) / 2 - 10)
        bubble.zPosition = CGFloat(ZPosition.HUDBackground.rawValue)
        customerNode.addChild(customerSprite)
        customerNode.addChild(bubble)
        addChild(customerNode)
        
        let wishSprite = SKSpriteNode(imageNamed: String(format: "wish_%@_%@", type, flavor))
        wishSprite.position = CGPoint(x: 0, y: bubble.size.height * 0.1)
        wishSprite.zPosition = bubble.zPosition + 1
        wishSprite.zPosition = CGFloat(ZPosition.HUDForeground.rawValue)
        bubble.addChild(wishSprite)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}