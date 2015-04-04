//
//  GameTableViewController.swift
//  Hangman
//
//  Created by Alexander G Edge on 02/04/2015.
//  Copyright (c) 2015 Alexander Edge. All rights reserved.
//

import UIKit

class GameTableViewController : UITableViewController {
    
    let CellIdentifier = "GameCell"
    var games : [Game] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Games", comment: "Games")
        loadGames()
    }
    
    @IBAction func refreshControlTriggered(sender : UIRefreshControl) {
        loadGames()
    }
    
    @IBAction func addButtonPressed(sender : UIBarButtonItem) {
        newGame()
    }
    
    private func loadGames() {
        self.refreshControl?.beginRefreshing()
        Game.fetchAll({ (games : [Game], error : NSError?) -> Void in
            self.refreshControl?.endRefreshing()
            if (error != nil) {
                self.showError(error!)
            } else {
                self.games = games
                self.tableView.reloadData()
            }
        })
    }
    
    private func newGame() {
        
        Game.startNew({ (game : Game?, error : NSError?) -> Void in
            if (error != nil) {
                self.showError(error!)
            } else {
                self.tableView.beginUpdates()
                self.games.insert(game!, atIndex: 0)
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
                self.tableView.endUpdates()
            }
        })
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath) as GameCell
        
        let game = games[indexPath.row]
        cell.wordLabel?.attributedText = NSAttributedString(string: game.displayString, attributes: [NSKernAttributeName : 5.0])
        
        let usedLetters = game.usedLetters as NSArray
        cell.usedLettersLabel?.text = usedLetters.componentsJoinedByString(",")
        
        switch game.state {
        case .InProgress:
            cell.gameStateLabel?.text = NSLocalizedString("Remaining", comment: "Remaining").uppercaseStringWithLocale(NSLocale.currentLocale())
            cell.guessesRemainingLabel?.attributedText = game.guessesRemainingAttributedString()
            break
        case .Win:
            cell.gameStateLabel?.text = NSLocalizedString("You win", comment: "You win").uppercaseStringWithLocale(NSLocale.currentLocale())
            cell.guessesRemainingLabel?.text = "😏"
            break
        case .Lose:
            cell.gameStateLabel?.text = NSLocalizedString("You lose", comment: "You lose").uppercaseStringWithLocale(NSLocale.currentLocale())
            cell.guessesRemainingLabel?.text = "😞"
            break
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let game = self.games[indexPath.row]
        
        if game.state == .InProgress {
            
            let alert = UIAlertController(title: NSLocalizedString("Guess", comment: "Guess"), message: NSLocalizedString("Which letter?", comment: "Which letter?"), preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler { (textField : UITextField!) -> Void in
                
                textField.autocapitalizationType = .AllCharacters
                textField.keyboardType = .ASCIICapable
            }
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.Default, handler: { action in
                if let textField = alert.textFields?.first as? UITextField {
                    
                    NSLog("send \(textField.text)")
                    
                    let letter = textField.text
                    game.guessLetter(letter, completion: { error in
                        if (error != nil) {
                            self.showError(error!)
                        } else {
                            tableView.reloadData()
                        }
                    })
                }
            }))
            
            presentViewController(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: NSLocalizedString("No more guesses", comment: "No more guesses"), message: game.state == .Win ? NSLocalizedString("You won!", comment: "You won!") : NSLocalizedString("You lost!", comment: "You lost!"), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: "Close"), style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    private func showError(error : NSError) {
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: error.localizedDescription, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: "Close"), style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
}