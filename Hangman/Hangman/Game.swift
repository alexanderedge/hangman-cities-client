//
//  Game.swift
//  Hangman
//
//  Created by Alexander G Edge on 02/04/2015.
//  Copyright (c) 2015 Alexander Edge. All rights reserved.
//

import UIKit

let kHangmanBaseURL = "http://hangman-cities.herokuapp.com"
let kHangmanErrorDomain = "uk.co.alexedge.hangman.game"
let kHangmanMaxGuesses : UInt = 10


class Game {
    
    enum GameState : UInt {
        case  InProgress = 0, Win = 1, Lose = 2
    }
    
    var gameId : UInt
    var displayString : String = ""
    var usedLetters : [String] = []
    var guessesRemaining : UInt = kHangmanMaxGuesses
    var state : GameState = .InProgress
    
    init(gameId : UInt) {
        self.gameId = gameId
    }
    
    class func gameWithJSON(json : NSDictionary, error : NSErrorPointer) -> Game? {
        if let gameId = json["game_id"] as? UInt {
            var game = Game(gameId : gameId)
            if game.updateWithJSON(json,error: error) {
                return game
            }
        }
        return nil
    }
    
    class func fetchAll(completion:(([Game],NSError?) -> Void)?) {
        let req = NSMutableURLRequest(URL: NSURL(string: kHangmanBaseURL)!.URLByAppendingPathComponent("games"))
        req.HTTPMethod = "GET"
        NSURLSession.sharedSession().dataTaskWithRequest(req, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                var decodeError : NSError?
                if let responseArray = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &decodeError) as? NSArray {
                    
                    var gameArray : [Game] = []
                    // convert the json to Game objects
                    for json in responseArray {
                        if let gameJSON = json as? NSDictionary {
                            if let game = Game.gameWithJSON(gameJSON, error: nil) {
                                gameArray.append(game)
                            }
                        }
                    }
                    
                    if (completion != nil) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion!(gameArray,nil)
                        })
                    }

                    
                } else {
                    // JSON decode error
                    if (completion != nil) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion!([],decodeError)
                        })
                    }
                }
            } else {
                // error guessing letter
                if (completion != nil) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion!([],error)
                    })
                }
            }
        }).resume()
    }
    
    class func startNew(completion : ((Game?, error : NSError?) -> Void)?) {
        let req = NSMutableURLRequest(URL: NSURL(string: kHangmanBaseURL)!.URLByAppendingPathComponent("games/new"))
        req.HTTPMethod = "POST"
        NSURLSession.sharedSession().dataTaskWithRequest(req, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                var decodeError : NSError?
                if let gameJSON = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &decodeError) as? NSDictionary {
                    
                    var createError : NSError?
                    let game = Game.gameWithJSON(gameJSON, error: &createError)
                    
                    if (completion != nil) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion!(game,error: createError)
                        })
                    }
                    
                } else {
                    // JSON decode error
                    if (completion != nil) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion!(nil,error: decodeError)
                        })
                    }
                }
            } else {
                // error guessing letter
                if (completion != nil) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion!(nil,error: error)
                    })
                }
            }
        }).resume()
    }
    
    func updateWithJSON(json : NSDictionary, error : NSErrorPointer) -> Bool {
        
        if let displayString = json["display_word"] as? String {
            if let usedLetters = json["letters_used"] as? NSString {
                if let guessesRemaining = json["guesses_remaining"] as? UInt {
                    if let state = json["state"] as? UInt {
                        self.displayString = displayString
                        self.usedLetters = usedLetters.componentsSeparatedByString(",") as [String]
                        self.guessesRemaining = guessesRemaining
                        self.state = GameState(rawValue: state)!
                        return true
                    }
                }
            }
        }
        
        // JSON data missing one or more fields
        if (error != nil) {
            error.memory = NSError(domain: kHangmanErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("JSON data incomplete", comment: "JSON data incomplete")])
        }
        return false
    }
    
    func guessLetter(letter : String, completion : (NSError? -> Void)?) {
        
        // send the letter to the webservice and update self
        // with the response
        let urlString = "\(kHangmanBaseURL)/games/\(gameId)/guess?letter=\(letter)"
        let req = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        req.HTTPMethod = "POST"
        NSURLSession.sharedSession().dataTaskWithRequest(req, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                var decodeError : NSError?
                if let responseJSON = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &decodeError) as? NSDictionary {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let httpResponse = response as NSHTTPURLResponse
                        if httpResponse.statusCode == 400 {
                            if let errorDescription: String = responseJSON["error"] as? String {
                                completion?(NSError(domain: kHangmanErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : errorDescription]));
                            } else {
                                completion?(NSError(domain: kHangmanErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Unknown error", comment: "Unknown error")]));
                            }
                        } else {
                            var updateError : NSError?
                            if !self.updateWithJSON(responseJSON,error: &updateError) {
                                completion?(nil);
                            } else {
                                completion?(updateError);
                            }
                        }
                    })
                } else {
                    // JSON decode error
                    if (completion != nil) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion!(decodeError)
                        })
                    }
                    
                }
            } else {
                if (completion != nil) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion!(error)
                    })
                }
            }
        }).resume()
    }
    
    func guessesRemainingAttributedString () -> NSAttributedString {
        // the guesses remaining colour will span green (120 deg) to red (0)
        let hue : CGFloat = CGFloat(guessesRemaining) / CGFloat(kHangmanMaxGuesses) * 120.0 / 360.0
        return NSMutableAttributedString(string: "\(guessesRemaining)", attributes: [NSForegroundColorAttributeName : UIColor(hue: hue, saturation: 1, brightness: 0.8, alpha: 1)])
    }
    
}