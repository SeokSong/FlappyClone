//
//  GameScene.swift
//  FlappyClone
//
//  Created by Seok Song on 6/7/23.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory{
    static let Ghost: UInt32 = 0x1 << 1
    static let Ground: UInt32 = 0x1 << 2
    static let Pipe: UInt32 = 0x1 << 3
    static let Score: UInt32 = 0x1 << 4
    
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var Ground = SKSpriteNode()
    var Ghost = SKSpriteNode()
    var dead = Bool()
    
    var score = Int()
    let scoreLabel = SKLabelNode()
    
    var wallPair = SKNode()
    
    var moveAndRemove = SKAction()
    var gameStarted = Bool()
    
    var restartButton = SKSpriteNode()
    
    func restartGame(){
        self.removeAllChildren()
        self.removeAllActions()
        
        dead = false
        gameStarted = false
        score = 0
        createGame()
    }
    
    func createGame(){
        
        for i in 0..<2{
            let background = SKSpriteNode(imageNamed: "Background")
            background.anchorPoint = CGPointZero
            background.position = CGPointMake(CGFloat(i) * self.frame.width - 350, -400)
            background.name = "background"
            background.size = (self.view?.bounds.size)!
            self.addChild(background)
        }
        
        self.physicsWorld.contactDelegate = self //handle any contact physics
        
        scoreLabel.position = CGPoint(x: self.frame.width / 2 - 250, y : self.frame.height / 2 - 100)
        scoreLabel.zPosition = 5
        scoreLabel.color = SKColor.red
        scoreLabel.text = "\(score)"
        self.addChild(scoreLabel)
        
        
        Ground = SKSpriteNode(imageNamed: "Ground")
        Ground.setScale(0.5)

        Ground.position = CGPoint(x: (self.frame.width / 2) - 250, y: -400)

        Ground.physicsBody = SKPhysicsBody(rectangleOf: Ground.size)
        Ground.physicsBody?.categoryBitMask = PhysicsCategory.Ground
        Ground.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        Ground.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        Ground.physicsBody?.affectedByGravity = false
        Ground.physicsBody?.isDynamic = false

     
        Ground.zPosition = 3 //above everything

        self.addChild(Ground)

        Ghost = SKSpriteNode(imageNamed: "Ghost")
        Ghost.size = CGSize(width: 60, height: 70)
        Ghost.position = CGPoint(x: self.frame.width / 2 - 250, y : self.frame.height / 2 - 350)

        Ghost.physicsBody = SKPhysicsBody(circleOfRadius: Ghost.frame.height / 2)
        Ghost.physicsBody?.categoryBitMask = PhysicsCategory.Ghost
        Ghost.physicsBody?.collisionBitMask = PhysicsCategory.Ground | PhysicsCategory.Pipe
        Ghost.physicsBody?.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Pipe | PhysicsCategory.Score
        Ghost.physicsBody?.affectedByGravity = false
        Ghost.physicsBody?.isDynamic = true

        Ghost.zPosition = 2 //above anything > 2


        self.addChild(Ghost)
    }
    
    override func didMove(to view: SKView) {
        
        createGame()
    }
    
    func createButton(){
        restartButton = SKSpriteNode(imageNamed: "RestartBtn")
        restartButton.size = CGSizeMake(200, 100)
        restartButton.position = CGPoint(x: self.frame.width / 2 - 200, y: self.frame.height / 2 - 200)
        restartButton.zPosition = 6
        self.addChild(restartButton)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if firstBody.categoryBitMask  == PhysicsCategory.Score && secondBody.categoryBitMask == PhysicsCategory.Ghost {
            
            score += 1
            
            scoreLabel.text = "\(score)"
            
            firstBody.node?.removeFromParent()
        }
        
        else if firstBody.categoryBitMask  == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Score{
            score += 1
            
            scoreLabel.text = "\(score)"
            
            secondBody.node?.removeFromParent()
        }
        
        else if firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Pipe || firstBody.categoryBitMask == PhysicsCategory.Pipe && secondBody.categoryBitMask == PhysicsCategory.Ghost{
            
            
            enumerateChildNodes(withName: "pipePairs", using: {
                (node, err) in
                node.speed = 0
                self.removeAllActions()
            })
            if dead == false{
                dead = true
                createButton()
            }
            
        }
        else if firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Ground || firstBody.categoryBitMask == PhysicsCategory.Ground && secondBody.categoryBitMask == PhysicsCategory.Ghost{
            
            
            enumerateChildNodes(withName: "pipePairs", using: {
                (node, err) in
                node.speed = 0
                self.removeAllActions()
            })
            if dead == false{
                dead = true
                createButton()
            }
            
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameStarted == false { // Game started
            gameStarted = true
            Ghost.physicsBody?.affectedByGravity = true
            
            let spawn = SKAction.run {
                self.createPipes()
            }
            
            let delay = SKAction.wait(forDuration: 1.5)
            let spawnDelay = SKAction.sequence([spawn, delay])
            let spawnDelayForever = SKAction.repeatForever(spawnDelay)
            self.run(spawnDelayForever)
            
            let distance = self.frame.width + wallPair.frame.width
            let movePipes = SKAction.moveBy(x: -distance - 100, y: 0, duration: TimeInterval(0.008 * distance))
            let removePipes = SKAction.removeFromParent()
            moveAndRemove = SKAction.sequence([movePipes, removePipes])
            
            Ghost.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            Ghost.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 90))
        } else {
            if dead == true {
                // can no longer jump
            } else {
                Ghost.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                Ghost.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 90))
            }
        }
        
        for touch in touches{
            let location = touch.location(in: self)
            
            if dead == true{
                if restartButton.contains(location){
                    restartGame()
                }
            }
        }
    }

    
    func createPipes(){
        
        wallPair = SKNode()
        wallPair.name = "pipePairs"
        
        let scoreNode = SKSpriteNode(imageNamed: "Coin")
        scoreNode.size = CGSize(width: 50, height: 50)
        scoreNode.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2 - 350)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: scoreNode.size)
        scoreNode.physicsBody?.affectedByGravity = false
        scoreNode.physicsBody?.isDynamic = false
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.Score
        scoreNode.physicsBody?.collisionBitMask = 0
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        scoreNode.color = SKColor.blue
        
        
        let topPipe = SKSpriteNode(imageNamed: "Wall")
        let bottomPipe = SKSpriteNode(imageNamed: "Wall")
        
        topPipe.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2)

        bottomPipe.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2 - 700)
        
        topPipe.setScale(0.5)
        bottomPipe.setScale(0.5)
        
        topPipe.physicsBody = SKPhysicsBody(rectangleOf: topPipe.size)
        topPipe.physicsBody?.categoryBitMask  = PhysicsCategory.Pipe
        topPipe.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        topPipe.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.affectedByGravity = false
        
        bottomPipe.physicsBody = SKPhysicsBody(rectangleOf: bottomPipe.size)
        bottomPipe.physicsBody?.categoryBitMask  = PhysicsCategory.Pipe
        bottomPipe.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        bottomPipe.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.affectedByGravity = false
        
        topPipe.zRotation = CGFloat(Double.pi) //180
        
        wallPair.addChild(topPipe)
        wallPair.addChild(bottomPipe)
        wallPair.addChild(scoreNode)
        
        wallPair.zPosition = 1 // every back of the scence
        
        let randomPosition = CGFloat.random(min: -100, max: 200)
        wallPair.position.y = wallPair.position.y + randomPosition
        
        
        self.addChild(wallPair)
        wallPair.run(moveAndRemove)
    }
    
    override func update(_ currentTime: CFTimeInterval){
        if gameStarted == true{
            if dead == false{
                enumerateChildNodes(withName: "background", using: {
                    (node, err) in
                    
                    var background = node as! SKSpriteNode
                    background.position = CGPointMake(background.position.x - 2, background.position.y)
                    
                    if background.position.x <= -background.size.width{
                        background.position = CGPoint(x: background.position.x + background.size.width * 2 - 200, y: background.position.y)
                    }
                })
            }
        }
    }
}
