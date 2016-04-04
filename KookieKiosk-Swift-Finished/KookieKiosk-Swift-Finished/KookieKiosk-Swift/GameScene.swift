//
//  GameScene.swift
//  KookieKiosk-Swift
//
//  Created by Barbara Reichart on 14/07/14.
//  Copyright (c) 2014 Barbara Reichart. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, GameStateDelegate {
    var money = 0
    var stockItems = [StockItem]()
    var stockItemConfigurations = [String: [String: NSNumber]]()
    
    var moneyLabel = SKLabelNode(fontNamed: "TrebuchetMS-Bold")
    
    var customer : Customer?
    var timeOfLastCustomer : CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    var timeTillNextCustomer : CFTimeInterval = CFTimeInterval(Float((arc4random() % 15 + 15)) * TimeScale)

    override func didMoveToView(view: SKView) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveGameData", name: "saveGameData", object: nil)
        
        // Draw background
        let background = SKSpriteNode(imageNamed: "bg_kookiekiosk")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = CGFloat(ZPosition.background.rawValue)
        addChild(background)
        
        // Draw HUD in top right corner that displays the amount of money the player has
        let moneyBackground = SKSpriteNode(imageNamed: "bg_money")
        moneyBackground.position = CGPoint(x: size.width - moneyBackground.size.width/2 - 10, y: size.height - moneyBackground.size.height/2 - 13)
        moneyBackground.zPosition = CGFloat(ZPosition.HUDBackground.rawValue)
        addChild(moneyBackground)
        
        moneyLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        moneyLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Top
        moneyLabel.position = CGPoint(x: size.width - 60, y: size.height - 115)
        moneyLabel.fontColor = SKColor(red: 156/255.0, green: 179/255.0, blue: 207/255.0, alpha: 1.0)
        moneyLabel.fontSize = 50
        moneyLabel.zPosition = CGFloat(ZPosition.HUDForeground.rawValue)
        addChild(moneyLabel)
        
        loadGameData()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "scheduleNotifications", name: "scheduleNotifications", object: nil)
    }
    
    func updateMoneyBy(delta : Int) {
        let deltaLabel = SKLabelNode(fontNamed: "TrebuchetMS-Bold")
        if delta < 0 {
            deltaLabel.fontColor = SKColor(red: 198/255.0, green: 139/255.0, blue: 207/255.0, alpha: 1.0)
        } else {
            deltaLabel.fontColor = SKColor(red: 156/255.0, green: 179/255.0, blue: 207/255.0, alpha: 1.0)
        }
        deltaLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        deltaLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Bottom
        deltaLabel.position = moneyLabel.position
        deltaLabel.text = String(format: "%i $", delta)
        deltaLabel.fontSize = moneyLabel.fontSize
        deltaLabel.zPosition = CGFloat(ZPosition.HUDForeground.rawValue)
        addChild(deltaLabel)
        
        let moveLabelAction = SKAction.moveBy(CGVector(dx: 0, dy: 20), duration: 0.5)
        let fadeLabelAction = SKAction.fadeOutWithDuration(0.5)
        let labelAction = SKAction.group([moveLabelAction, fadeLabelAction])
        deltaLabel.runAction(labelAction, completion: {deltaLabel.removeFromParent()})

        money += delta
        moneyLabel.text = String(format: "%i $", money)
    }
    
    // MARK: Load and save plist file
    func saveGameData() {
        let path = documentFilePath(fileName: "gamedata.plist")
        let stockItemData = NSMutableArray()
        for stockItem : StockItem in stockItems {
            stockItemData.addObject(stockItem.data())
        }
        var stockItemConfigurationsObjects = [AnyObject]()
        var stockItemConfigurationsKeys = [NSCopying]()
        for (key, stockItemConfiguration) in stockItemConfigurations {
            stockItemConfigurationsKeys.append(key)
            stockItemConfigurationsObjects.append(stockItemConfiguration)
        }
        
        let stockItemConfigurationsNSDictionary = NSDictionary(objects: stockItemConfigurationsObjects, forKeys: stockItemConfigurationsKeys)
        let objects = [stockItemConfigurationsNSDictionary, money, stockItemData]
        let keys = ["stockItemConfigurations", "money", "stockItemData"]
        let gameData = NSDictionary(objects: objects, forKeys: keys)
        let success = gameData.writeToFile(path, atomically: true)
        print(success)
    }
    
    func loadGameData() {
        var path = documentFilePath(fileName: "gamedata.plist")
        var gameData : NSDictionary? = NSDictionary(contentsOfFile: path)
        // Load gamedata template from mainBundle if no saveFile exists
        if gameData == nil {
            let mainBundle = NSBundle.mainBundle()
            path = mainBundle.pathForResource("gamedata", ofType: "plist")!
            gameData = NSDictionary(contentsOfFile: path)
        }
        
        stockItemConfigurations = gameData!["stockItemConfigurations"] as! [String: [String: NSNumber]]
        money = gameData!["money"] as! Int
        moneyLabel.text = String(format: "%i $", money)
        let stockItemDataSet = gameData!["stockItemData"] as! [[String: AnyObject]]
        for stockItemData in stockItemDataSet {
            let itemType = stockItemData["type"] as AnyObject? as! String
            let stockItemConfiguration = stockItemConfigurations[itemType] as [String: NSNumber]!
            let stockItem  = StockItem(stockItemData: stockItemData, stockItemConfiguration: stockItemConfiguration, gameStateDelegate: self)
            let relativeX = stockItemData["x"] as AnyObject? as! Float
            let relativeY = stockItemData["y"] as AnyObject? as! Float
            stockItem.position = CGPoint(x: Int(relativeX * Float(size.width)), y: Int(relativeY * Float(size.height)))
            addChild(stockItem)
            stockItems.append(stockItem)
        }
    }
    
    func documentFilePath(fileName fileName: String) -> String {
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let fileURL = documentsURL.URLByAppendingPathComponent(fileName)
        return fileURL.path!
    }
    
    func gameStateDelegateChangeMoneyBy(delta delta: Int) -> Bool {
        if (delta < 0 && money >= -delta) || delta > 0 {
            updateMoneyBy(delta)
            return true
        } else  {
            return false
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        for stockItem in stockItems {
            stockItem.update()
        }
        // 1 Check whether it is time for a customer to appear
        let currentTimeAbsolute = CFAbsoluteTimeGetCurrent()
        if customer == nil && currentTimeAbsolute - timeOfLastCustomer > timeTillNextCustomer {
            // 2 Make a list of potential wishes the customer could have
            var potentialWishes = [StockItem]()
            for stockItem : StockItem in stockItems {
                if stockItem.state == State.selling || stockItem.state == State.stocked {
                    potentialWishes.append(stockItem)
                }
            }
            // 3 Select one of the potential wishes randomly and spawn the customer with it
            if potentialWishes.count > 0 {
                let random = arc4random() % UInt32(potentialWishes.count)
                let randomStockItem = potentialWishes[Int(random)]
                customer = Customer(type: randomStockItem.type, flavor: randomStockItem.flavor)
                customer!.position = CGPoint(x: frame.size.width + customer!.calculateAccumulatedFrame().size.width / 2, y: customer! .calculateAccumulatedFrame().size.height / 2)
                // 4 Animate the customer
                let moveLeft = SKAction.moveBy(CGVector(dx: -customer!.calculateAccumulatedFrame().size.width, dy: 0), duration: 1)
                customer?.runAction(moveLeft)
                addChild(customer!)
            }
        }
    }
    
    func gameStateServeCustomerWithItemOfType(type type: String, flavor: String) {
        // 1 Check if the player has served the correct item for the customer
        if customer?.type == type && customer?.flavor == flavor {
            gameStateDelegateChangeMoneyBy(delta: 50)
            let playSound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: true)
            runAction(playSound)
        } else {
            let playSound = SKAction.playSoundFileNamed("hit.wav", waitForCompletion: true)
            runAction(playSound)
        }
        if customer != nil {
            // 2 Clean up customer
            let moveRight = SKAction.moveBy(CGVector(dx: customer!.calculateAccumulatedFrame().size.width, dy: 0), duration: 1)
            customer!.runAction(moveRight, completion:{
                self.customer?.removeFromParent()
                self.customer = nil
            })
            // 3 Setup spawn of next customer
            timeOfLastCustomer = CFAbsoluteTimeGetCurrent()
            timeTillNextCustomer = CFTimeInterval(Float((arc4random() % 15 + 15)) * TimeScale)
        }
    }
    
    func scheduleNotificationWith(message message: String, intervalInSeconds: NSTimeInterval, badgeNumber: Int) {
        // 1 Create empty notification
        let localNotification = UILocalNotification()
        
        // 2 Calculate notification time using NSDate
        let now = NSDate()
        let notificationTime = now.dateByAddingTimeInterval(intervalInSeconds)
        
        // 3 Set properties of your notification
        localNotification.alertBody = message
        localNotification.fireDate = notificationTime
        localNotification.timeZone = NSTimeZone.defaultTimeZone()
        localNotification.applicationIconBadgeNumber = badgeNumber
        localNotification.soundName = UILocalNotificationDefaultSoundName
        
        // 4 Schedule the notification
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func scheduleNotifications() {
        let itemsSortedByNotificationTime = stockItems.sort({$0.notificationTime() < $1.notificationTime()})
        var count = 1
        for stockItem in itemsSortedByNotificationTime {
            let notificationMessage = stockItem.notificationMessage()
            if notificationMessage != nil {
                scheduleNotificationWith(message: notificationMessage!, intervalInSeconds: stockItem.notificationTime(), badgeNumber: count)
                count++
            }
        }
    }
  
}