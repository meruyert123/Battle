//
//  SceneDelegate.swift
//  Rock Paper Scissors
//
//  Created by Meruert on 22.04.2023.
//

import UIKit

class ViewController: UIViewController {
    var displayLink: CADisplayLink?
    let gameBoardView = UIView()
    var images = [UIImageView]()
    var scores = [String: Int]()
    let winningScore = 50
    let maxImages = 50
    let imageTypes = ["rock", "scissors", "paper"]
    let strengthMap = ["rock": "scissors", "scissors": "paper", "paper": "rock"]
    var scoreLabels = [String: UILabel]()
    var isGameRunning = false
    var isStarting = true
    var alertView: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(gameBoardView)
        // Set up game board view
        gameBoardView.frame = view.safeAreaLayoutGuide.layoutFrame.inset(by: UIEdgeInsets(top: 180, left: 0, bottom: 20, right: 0))
        let patternImage = UIImage(named: "back")
        let backgroundColor = UIColor(patternImage: patternImage!)
        gameBoardView.backgroundColor = backgroundColor
        
        // Create start button
        let startButton = createButton(title: "Start", target: self, action: #selector(startButtonTapped), bgColor: .green)
        startButton.tag = 17
        startButton.frame = CGRect(x: view.frame.width*0.5, y: 80, width: 80, height: 30)
        view.addSubview(startButton)
         
    }
    
    func createButton(title: String, target: Any?, action: Selector, bgColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.backgroundColor = bgColor
        button.tintColor = .black
        return button
    }
    
    @objc func startButtonTapped() {
        if let viewWithTag = self.view.viewWithTag(17) {
            viewWithTag.removeFromSuperview()
        }
        if isGameRunning {
            // User clicked Restart button
            restartGame()
        } else {
            // User clicked Start button
            startImageAnimations()
            isGameRunning = true
        }
    }
    @objc func startImageAnimations() {
        // Use CADisplayLink to update image positions
        for (index, type) in imageTypes.enumerated() {
            let label = UILabel()
            label.text = "\(type): 0/\(winningScore)"
            label.font = UIFont.systemFont(ofSize: 20)
            label.textColor = .black
            label.frame = CGRect(x: view.frame.width*0.1, y: 60 + 30*CGFloat(index), width: view.frame.width*0.4, height: 30)
            //            label.backgroundColor = .systemMint
            view.addSubview(label)
            scoreLabels[type] = label
        }
        // Add images to game board view
        for i in 0..<maxImages {
            let imageType = imageTypes.randomElement()!
            let imageName = "\(imageType)\(i)"
            let image = UIImageView(image: UIImage(named: imageType))
            image.frame = CGRect(x: CGFloat.random(in: 0..<gameBoardView.bounds.width - 35),
                                 y: CGFloat.random(in: 0..<gameBoardView.bounds.height - 35),
                                 width: 35, height: 35)
            image.isUserInteractionEnabled = true
            images.append(image)
            scores[imageType, default: 0] += 1
            gameBoardView.addSubview(image)
        }
        displayLink = CADisplayLink(target: self, selector: #selector(updateImagePositions))
        displayLink?.add(to: .current, forMode: .default)
        
    }
    @objc func restartGame() {
        // Remove all images from the game board view
        for image in images {
            image.removeFromSuperview()
        }
        images.removeAll()
        
        // Update score labels with current scores and reset scores
        for (type, label) in scoreLabels {
            scores[type] = 0
            label.text = ""
        }
        
        alertView?.dismiss(animated: true, completion: nil)
        alertView = nil
        
        // Start image animations
        startImageAnimations()
        isGameRunning = false
    }
    

    @objc func stopImageAnimations() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc func continueImageAnimations() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateImagePositions))
        displayLink?.add(to: .current, forMode: .default)
    }
    
    @objc func updateImagePositions() {
        // Move images randomly
        for image in images {
            let newX = image.center.x + CGFloat.random(in: -5..<5)
            let newY = image.center.y + CGFloat.random(in: -5..<5)
            
            // Check if the new position is within the game board view bounds
            let newFrame = CGRect(x: newX - image.frame.width/2,
                                  y: newY - image.frame.height/2,
                                  width: image.frame.width,
                                  height: image.frame.height)
            if gameBoardView.bounds.contains(newFrame) {
                // If the new position is within the bounds, move the image to the new position
                UIView.animate(withDuration: 0.5, delay: 0.1, options: [], animations: {
                    image.center = CGPoint(x: newX, y: newY)
                }, completion: nil)
            } else {
                // If the new position is outside the bounds, adjust the position so that the image stays within the bounds
                var adjustedX = newX
                var adjustedY = newY
                if newFrame.minX < gameBoardView.bounds.minX {
                    adjustedX = gameBoardView.bounds.minX + image.frame.width/2
                } else if newFrame.maxX > gameBoardView.bounds.maxX {
                    adjustedX = gameBoardView.bounds.maxX - image.frame.width/2
                }
                if newFrame.minY < gameBoardView.bounds.minY {
                    adjustedY = gameBoardView.bounds.minY + image.frame.height/2
                } else if newFrame.maxY > gameBoardView.bounds.maxY {
                    adjustedY = gameBoardView.bounds.maxY - image.frame.height/2
                }
                UIView.animate(withDuration: 0.5, delay: 0.1, options: [], animations: {
                    image.center = CGPoint(x: adjustedX, y: adjustedY)
                }, completion: nil)
            }
            // Update image position with animation
        }
        
        // Handle collisions
        handleCollisions()
        
        for (type, count) in scores {
            if let label = scoreLabels[type] {
                label.text = "\(type): \(count)/\(winningScore)"
            }
        }
        
        // Check for end of game conditions
        if scores.values.contains(winningScore) || images.filter { $0.image == images.first?.image }.count == maxImages {
            endGame()
        }
    }
    
    func handleCollisions() {
        // Check for collisions between images
        for i in 0..<images.count {
            let image1 = images[i]
            for j in (i+1)..<images.count {
                let image2 = images[j]
                
                if image1.frame.intersects(image2.frame) {
                    // Determine winner and loser based on image types
                    let type1 = image1.image == UIImage(named: "rock") ? "rock" :
                    image1.image == UIImage(named: "scissors") ? "scissors" : "paper"
                    let type2 = image2.image == UIImage(named: "rock") ? "rock" :
                    image2.image == UIImage(named: "scissors") ? "scissors" : "paper"
                    
                    if strengthMap[type1] == type2 {
                        // Image 1 wins
                        swapImagesIfNeeded(image1, image2)
                        scores[type1, default: 0] += 1
                        scores[type2, default: 0] -= 1
                    } else if strengthMap[type2] == type1 {
                        // Image 2 wins
                        swapImagesIfNeeded(image2, image1)
                        scores[type2, default: 0] += 1
                        scores[type1, default: 0] -= 1
                    }
                }
            }
        }
    }
    
    func swapImagesIfNeeded(_ strongerImage: UIImageView, _ weakerImage: UIImageView) {
        let strongerType = strongerImage.image == UIImage(named: "rock") ? "rock" :
        strongerImage.image == UIImage(named: "scissors") ? "scissors" : "paper"
        let weakerType = weakerImage.image == UIImage(named: "rock") ? "rock" :
        weakerImage.image == UIImage(named: "scissors") ? "scissors" : "paper"
        
        if strengthMap[strongerType] == weakerType {
            // Swap images
            weakerImage.image = strongerImage.image
        }
    }
    func endGame() {
        // Stop image animations
        for (type, score) in scores {
            if score >= winningScore {
                // Stop the game
                stopImageAnimations()
                isGameRunning = false
                
                // Show an alert indicating the winner
                let message = "Congratulations! \(type.capitalized) won!"
                alertView = UIAlertController(title: "Game Over", message: message, preferredStyle: .alert)
                let action = UIAlertAction(title: "Play Again", style: .default) { [weak self] _ in
                    self?.restartGame()
                }
                alertView?.addAction(action)
                present(alertView!, animated: true, completion: nil)
            }
        }
    }
    
    
    func resetGame() {
        // Remove existing images from the game board
        for image in images {
            image.removeFromSuperview()
        }
        images.removeAll()
        
        // Reset scores dictionary
        scores = [String: Int]()
        
        // Add new images to game board view
        for i in 0..<maxImages {
            let imageType = imageTypes.randomElement()!
            let imageName = "\(imageType)\(i)"
            let image = UIImageView(image: UIImage(named: imageType))
            image.frame = CGRect(x: CGFloat.random(in: 0..<gameBoardView.bounds.width - 35),
                                 y: CGFloat.random(in: 0..<gameBoardView.bounds.height - 35),
                                 width: 35, height: 35)
            image.isUserInteractionEnabled = true
            images.append(image)
            scores[imageType, default: 0] += 1
            gameBoardView.addSubview(image)
        }
    }
}
