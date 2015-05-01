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

typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>

func JSONString(object: JSON?) -> String? {
    return object as? String
}

func JSONUInt(object: JSON?) -> UInt? {
    return object as? UInt
}

func JSONObject(object: JSON?) -> JSONDictionary? {
    return object as? JSONDictionary
}

protocol JSONDecodable {
    static func decode(json: JSON, error : NSErrorPointer) -> Self?
}

struct Game : JSONDecodable {
    
    enum GameState : UInt {
        case  InProgress = 0, Win = 1, Lose = 2
    }
    
    let gameId : UInt
    let displayString : String
    let usedLetters : [String]
    let guessesRemaining : UInt
    let state : GameState
    
    static func decode(json : JSON, error : NSErrorPointer) -> Game? {
        if let id = JSONUInt(json["game_id"]), let displayString = JSONString(json["display_word"]), let usedLetters = JSONString(json["letters_used"]), let guessesRemaining = JSONUInt(json["guesses_remaining"]), let state = JSONUInt(json["state"]) {
            return Game(gameId: id, displayString: displayString, usedLetters: usedLetters.componentsSeparatedByString(",") as [String], guessesRemaining: guessesRemaining, state: GameState(rawValue: state)!)
        }
        // JSON data missing one or more fields
        if (error != nil) {
            error.memory = NSError(domain: kHangmanErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("JSON data incomplete", comment: "JSON data incomplete")])
        }
        return nil
    }
    
    static func fetchAll(completion:(([Game],NSError?) -> Void)?) {
        let req = NSMutableURLRequest(URL: NSURL(string: kHangmanBaseURL)!.URLByAppendingPathComponent("games"))
        req.HTTPMethod = "GET"
        NSURLSession.sharedSession().dataTaskWithRequest(req, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                var decodeError : NSError?
                if let responseArray = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &decodeError) as? JSONArray {
                    let gameOptionalArray = responseArray.map({ Game.decode($0, error: nil)})
                    let gameArray = gameOptionalArray.filter({ $0 != nil }).map( {$0!})
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion?(gameArray,nil)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion?([],decodeError)
                    })
                }
            } else {
                // error guessing letter
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion?([],error)
                })
            }
        }).resume()
    }
    
    static func startNew(completion : ((Game?, error : NSError?) -> Void)?) {
        let req = NSMutableURLRequest(URL: NSURL(string: kHangmanBaseURL)!.URLByAppendingPathComponent("games/new"))
        req.HTTPMethod = "POST"
        NSURLSession.sharedSession().dataTaskWithRequest(req, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                var decodeError : NSError?
                if let gameJSON = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &decodeError) as? NSDictionary {
                    
                    var createError : NSError?
                    let game = Game.decode(gameJSON, error: &createError)
                    
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
    
    
    
    func guessLetter(letter : String, completion : ((Game?,NSError?) -> Void)?) {
        let urlString = "\(kHangmanBaseURL)/games/\(gameId)/guess?letter=\(letter)"
        let req = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        req.HTTPMethod = "POST"
        NSURLSession.sharedSession().dataTaskWithRequest(req, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                var decodeError : NSError?
                if let responseJSON = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &decodeError) as? NSDictionary {
                    
                    let httpResponse = response as! NSHTTPURLResponse
                    if httpResponse.statusCode == 400 {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if let errorDescription: String = responseJSON["error"] as? String {
                                completion?(nil,NSError(domain: kHangmanErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : errorDescription]));
                            } else {
                                completion?(nil,NSError(domain: kHangmanErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Unknown error", comment: "Unknown error")]));
                            }
                        })
                        
                    } else {
                        var constructionError : NSError?
                        if let game = Game.decode(responseJSON, error: &constructionError) {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completion?(game,nil);
                            })
                        } else {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completion?(nil,constructionError);
                            })
                        }
                    }

                } else {
                    // JSON decode error
                    if (completion != nil) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion!(nil,decodeError)
                        })
                    }
                    
                }
            } else {
                if (completion != nil) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion!(nil,error)
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