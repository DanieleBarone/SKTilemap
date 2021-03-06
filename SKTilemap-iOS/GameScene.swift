//
//  GameScene.swift
//  SKTilemap
//
//  Created by Thomas Linthwaite on 07/04/2016.
//  Copyright (c) 2016 Tom Linthwaite. All rights reserved.
//

import SpriteKit

// MARK: GameScene
class GameScene: SKScene {
    
// MARK: Properties
    var tilemap: SKTilemap?
    let worldNode: SKNode
    var sceneCamera: Camera!
    
// MARK: Initialization
    override init(size: CGSize) {
        
        worldNode = SKNode()
        
        super.init(size: size)
        
        addChild(worldNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        
        /* Setup a basic Camera object to allow for panning/zooming. */
        sceneCamera = Camera(scene: self, view: view, worldNode: worldNode)
        addChild(sceneCamera)
        camera = sceneCamera
        
        /* Load Tilemap from .tmx file and add it to the scene through the worldNode. */
        if let tilemap = SKTilemap.loadTMX(name: "tilemap_orthogonal") {
            
            /* Print tilemap information to console, useful for debugging. */
            //tilemap.printDebugDescription()
            self.worldNode.addChild(tilemap)
            self.tilemap = tilemap
            
            /* Set the bounds for the tilemap. The bounds for the tilemap are different to those of the camera.
               These bounds origin is from the top left corner. But we only need to specify the distance from that corner. */
//             tilemap.displayBounds = CGRect(x: 64, y: 64, width: view.bounds.width - 128, height: view.bounds.height - 128)
            
            /* Note that if we did not set the above tilemap bounds, the tilemap itself will use the view bounds (view.bounds)
             as default. You only need to set these bounds if you are planning on not using the whole of the screen for
             to display your tilemap. You can change these bounds at any time, you are not required to set them before
             enabling tile clipping. */
            
            /* Set this to enable tile clipping outside the size of the view. */
            tilemap.enableTileClipping = true
            
            /* Set a custom alignment for the tilemap.
                0 - The layers left/bottom most edge will rest at 0 in the scene
                0.5 - The center of the layer will rest at 0 in the scene
                1 - The layers right/top most edge will rest at 0 in the scene
             
                It is not required to set this. The default is 0.5,0.5.
             */
            tilemap.alignment = CGPoint(x: 0.5, y: 0.5)
        }
        
        /* Set custom camera bounds to test tile clipping. */
//        sceneCamera.bounds = CGRect(x: -(view.bounds.width / 2) + 64,
//                                    y: -(view.bounds.height / 2) + 64,
//                                    width: view.bounds.width - 128,
//                                    height: view.bounds.height - 128)
        
        /* Create a temporary shape to test the bounds so its easy to see where they are. */
//        let boundsShape = SKShapeNode(rect: sceneCamera.bounds)
//        boundsShape.antialiased = false
//        boundsShape.lineWidth = 1
//        boundsShape.strokeColor = SKColor.blueColor()
//        boundsShape.zPosition = 1000
        
        /* NOTE: Adding the shape as a child of the camera. This stops it moving/scaling when the camera does! */
//        sceneCamera.addChild(boundsShape)
        /* There is one more step to ensure tileClipping works... Scroll down to the touches moved method. */
        
    }
    
// MARK: Input
    
    #if os(iOS)
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        for touch in touches {
            
            print("Touch Location: \(touch.locationInNode(self))")
            if let layer = tilemap?.getLayer(name: "ground layer") {
                
                print("Coord: \(layer.coordAtTouchPosition(touch))")
                if let coord = layer.coordAtTouchPosition(touch) {
                    
                    if let object = tilemap?.getObjectGroup(name: "object group")?.getObjectAtCoord(coord) {
                        print("Object Position: \(object.coord)")
                        
                        let spr = SKSpriteNode(imageNamed: "grass")
                        spr.position = worldNode.convertPoint(object.positionOnLayer(layer), fromNode: layer)
                        spr.zPosition = 100
                        worldNode.addChild(spr)
                    }
                }
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        for touch in touches {
            
            sceneCamera.updatePosition(touch)
            
            /* Will only work if tilemap.enableTileClipping = true 
               Increase the tileBufferSize to draw more tiles outside of the bounds. This can stop tiles that are part
               way in/out of the bounds to get fully displayed. Not giving a tileBufferSize will default it to 2. */
            tilemap?.clipTilesOutOfBounds(scale: sceneCamera.getZoomScale(), tileBufferSize: 1)
            /* You must call this function every time the camera moves/zooms. At the moment this is the easiest way to
               do it. But ideally the tilemap itself should know when it needs to update. Right now there is no way
               for the tilemap to know when the camera is being zoomed. Its something I may look in to, but the camera
               is not really part of thie project. */
        }

    }
    #endif
    
    #if os(OSX)
    override func mouseDown(theEvent: NSEvent) {
        
        print("Mouse Location: \(theEvent.locationInNode(self))")
        if let layer = tilemap?.getLayer(name: "ground layer") {
            
            print("Coord: \(layer.coordAtMousePosition(theEvent))")
            if let coord = layer.coordAtMousePosition(theEvent) {
                
                if let tile = layer.tileAtCoord(coord) {
                    
                    print("Tile Position: \(tile.position)")
                    if let object = tilemap?.getObjectGroup(name: "object group")?.getObjectAtCoord(coord) {
                        print("Object Position: \(object.position)")
                    }
                }
            }
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        sceneCamera.finishedInput()
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        
        sceneCamera.updatePosition(theEvent)
        tilemap?.clipTilesOutOfBounds()
        
    }
    
    override func didChangeSize(oldSize: CGSize) {
        
        if let scene = self.scene, let view = scene.view {
            
            /* Update the bounds for the tilemap and camera if the window size changes. */
            tilemap?.displayBounds = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
            
            sceneCamera.bounds = CGRect(x: -(view.bounds.width / 2),
                                        y: -(view.bounds.height / 2),
                                        width: view.bounds.width,
                                        height: view.bounds.height)
            
            tilemap?.clipTilesOutOfBounds()
        }
    }
    #endif
}