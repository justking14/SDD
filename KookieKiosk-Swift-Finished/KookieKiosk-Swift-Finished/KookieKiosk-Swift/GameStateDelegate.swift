//
//  GameStateDelegate.swift
//  KookieKiosk-Swift
//
//  Created by Barbara Reichart on 14/07/14.
//  Copyright (c) 2014 Barbara Reichart. All rights reserved.
//

protocol GameStateDelegate {
    
    func gameStateDelegateChangeMoneyBy(delta delta: Int) -> Bool
    func gameStateServeCustomerWithItemOfType(type type: String, flavor: String)
    
}
