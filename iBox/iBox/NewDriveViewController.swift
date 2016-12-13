//
//  NewDriveViewController.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/2/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import UIKit
import CoreData

class NewDriveViewController: UITableViewController {
    
    // MARK: - Properties
    
    var configuration: Configuration?
    
    // MARK: - Private Methods
    
    private func createNewDriveWithEntityName(entityName: String) -> Drive {
        
        assert(isSubEntity(entityNamed: entityName, ofEntityNamed: "Drive", inManagedObjectContext: Store.sharedInstance.managedObjectContext),
            "The specified entity is not a sub entity of Drive")
        
        // create new drive
        let newDrive = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: Store.sharedInstance.managedObjectContext) as! Drive
        
        // find or create ata interface for new drive
        
        var ataInterface: ATAInterface?
        
        // no interfaces yet
        if self.configuration!.ataInterfaces?.count == 0 || self.configuration!.ataInterfaces?.count == nil {
            
            ataInterface = NSEntityDescription.insertNewObjectForEntityForName("ATAInterface", inManagedObjectContext: Store.sharedInstance.managedObjectContext) as? ATAInterface
            ataInterface!.configuration = self.configuration!
        }
            
            // ATA interfaces exist
        else {
            
            // find latest ATA interface
            
            let fetchRequest = NSFetchRequest(entityName: "ATAInterface")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "configuration == %@", self.configuration!)
            
            var fetchError: NSError?
            var fetchResult: [AnyObject] = []
            do {
                fetchResult = try Store.sharedInstance.managedObjectContext.executeFetchRequest(fetchRequest)
            } catch {}
            
            assert(fetchError == nil, "Error occurred while fetching from store. (\(fetchError?.localizedDescription))")
            
            let newestATAInterface = fetchResult.last as! ATAInterface
            
            // get number of existing drives
            var numberOfDrivesInNewestATAInterface = 0
            
            if newestATAInterface.drives != nil {
                
                numberOfDrivesInNewestATAInterface = newestATAInterface.drives!.count
            }
            
            // set or create ATA interface
            switch numberOfDrivesInNewestATAInterface {
                
            // already has slave and master
            case maxDrivesPerATAInterface:
                
                // create new ATA interface
                let newIndex = self.configuration!.ataInterfaces!.count
                ataInterface = NSEntityDescription.insertNewObjectForEntityForName("ATAInterface", inManagedObjectContext: Store.sharedInstance.managedObjectContext) as? ATAInterface
                ataInterface!.configuration = self.configuration!
                ataInterface!.id = newIndex
                
                // set IRQ
                ataInterface!.irq = 14 + newIndex
                
            // doesnt have any drives
            case 0:
                
                ataInterface = newestATAInterface
                
                // newly created drives are master by default
                
            // add as slave
            default:
                
                ataInterface = newestATAInterface
                
                newDrive.master = false
            }
            
        }
        
        // set drive interface
        newDrive.ataInterface = ataInterface!
        
        return newDrive
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "newCDROMSegue" {
            
            // create new drive
            let newDrive = self.createNewDriveWithEntityName("CDRom") as! CDRom
            
            // set model object on VC
            let driveEditorVC = segue.destinationViewController as! DriveEditorViewController
            
            driveEditorVC.drive = newDrive
            
            driveEditorVC.navigationItem.hidesBackButton = true
        }
        
        if segue.identifier == "newHDDSegue" {
            
            // create new drive
            let newDrive = self.createNewDriveWithEntityName("HardDiskDrive") as! HardDiskDrive
            
            // set model object on VC
            let driveEditorVC = segue.destinationViewController as! DriveEditorViewController
            
            driveEditorVC.drive = newDrive
            
            driveEditorVC.navigationItem.hidesBackButton = true
        }
        
    }
    
}

// MARK: - Public Functions

public func isSubEntity(entityNamed entityName: String, ofEntityNamed parentEntityName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> Bool {
    
    let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: managedObjectContext)
    
    if let superEntity = entity!.superentity {
        
        if superEntity.name == parentEntityName {
            
            return true
        }
    }
    
    return false
}


