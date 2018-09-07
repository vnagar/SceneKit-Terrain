//
//  GameView.swift
//  macOS
//
//  Created by Vivek Nagar on 10/7/16.
//  Copyright (c) 2016 Vivek Nagar. All rights reserved.
//

import SceneKit

protocol GameInputDelegate {
    #if os(iOS)
    func handleTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    func handleTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    func handleTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    #elseif os(OSX)
    func handleMouseDown(with: NSEvent)
    func handleMouseUp(with: NSEvent)
    func handleMouseDragged(with: NSEvent)
    func handleKeyDown(with: NSEvent)
    func handleKeyUp(with: NSEvent)
    #endif
}

class GameView: SCNView {
    var eventsDelegate: GameInputDelegate?

    override func mouseDown(with event: NSEvent) {
        guard let eventsDelegate = eventsDelegate else {
            super.mouseDown(with: event)
            return
        }
        eventsDelegate.handleMouseDown(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        guard let eventsDelegate = eventsDelegate else {
            super.mouseUp(with: event)
            return
        }
        eventsDelegate.handleMouseUp(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let eventsDelegate = eventsDelegate else {
            super.mouseUp(with: event)
            return
        }
        eventsDelegate.handleMouseDragged(with: event)
    }
    
    override func keyDown(with event: NSEvent) {
        guard let eventsDelegate = eventsDelegate else {
            super.keyDown(with: event)
            return
        }
        eventsDelegate.handleKeyDown(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        guard let eventsDelegate = eventsDelegate else {
            super.keyUp(with: event)
            return
        }
        eventsDelegate.handleKeyUp(with: event)
    }
}
