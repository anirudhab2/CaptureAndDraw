//
//  DrawingSession.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 11/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

// A Session to manage undo, redo, update and reset actions
class DrawingSession: NSObject {

    fileprivate let maxSessionSize = 50
    fileprivate var undoSessionList: [Drawing] = []
    fileprivate var redoSessionList: [Drawing] = []
    fileprivate var backgroundSession: Drawing?
    
    override init() {
        super.init()
    }
    
    fileprivate func appendUndo(_ session: Drawing?) {
        if (session == nil) {
            return
        }
        
        if (undoSessionList.count >= maxSessionSize) {
            undoSessionList.removeFirst()
        }
        
        undoSessionList.append(session!)
    }
    
    fileprivate func appendRedo(_ session: Drawing?) {
        if (session == nil) {
            return
        }
        
        if (redoSessionList.count >= maxSessionSize) {
            redoSessionList.removeFirst()
        }
        
        redoSessionList.append(session!)
    }
    
    fileprivate func resetUndo() {
        undoSessionList.removeAll()
    }
    
    fileprivate func resetRedo() {
        redoSessionList.removeAll()
    }
    
    
    func lastSession() -> Drawing? {
        if (undoSessionList.last != nil) {
            return undoSessionList.last
        } else if (backgroundSession != nil) {
            return backgroundSession
        }
        
        return nil
    }
    
    func appendBackground(_ session: Drawing?) {
        if (session != nil) {
            backgroundSession = session
        }
    }
    
    func append(_ session: Drawing?) {
        appendUndo(session)
        resetRedo()
    }
    
    func undo() {
        if let lastSession = undoSessionList.last {
            appendRedo(lastSession)
            undoSessionList.removeLast()
        }
    }
    
    func redo() {
        if let lastSession = redoSessionList.last {
            appendUndo(lastSession)
            redoSessionList.removeLast()
        }
    }
    
    func reset() {
        resetUndo()
        resetRedo()
    }
    
    func canUndo() -> Bool {
        return (undoSessionList.count > 0)
    }
    
    func canRedo() -> Bool {
        return (redoSessionList.count > 0)
    }
    
    func canReset() -> Bool {
        let canUndo = self.canUndo()
        let canRedo = self.canRedo()
        return (canUndo || canRedo)
    }
}
