//
//  GameCell.swift
//  Hangman
//
//  Created by Alexander G Edge on 02/04/2015.
//  Copyright (c) 2015 Alexander Edge. All rights reserved.
//

import UIKit

class GameCell : UITableViewCell {
    
    @IBOutlet var wordLabel : UILabel?
    @IBOutlet var guessesRemainingLabel : UILabel?
    @IBOutlet var gameStateLabel : UILabel?
    @IBOutlet var usedLettersLabel : UILabel?
    
}
