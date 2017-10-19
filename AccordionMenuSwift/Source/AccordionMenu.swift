//
//  AccordionMenu.swift
//  AccordionMenu
//
//  Created by Victor on 7/6/16.
//  Copyright © 2016 Victor Sigler. All rights reserved.
//

import UIKit

open class AccordionTableViewController: UITableViewController {
    
    /// The number of elements in the data source
    open var total = 0
    
    /// The identifier for the parent cells.
    let parentCellIdentifier = "ParentCell"
    
    /// The identifier for the child cells.
    let childCellIdentifier = "ChildCell"
    
    /// The data source
    open var dataSource: [Parent]!
    
    /// Define wether can exist several cells expanded or not.
    open var numberOfCellsExpanded: NumberOfCellExpanded = .one
    
    /// Constant to define the values for the tuple in case of not exist a cell expanded.
    let noCellExpanded = (-1, -1)
    
    /// The index of the last cell expanded and its parent.
    var lastCellExpanded: (Int, Int)!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        lastCellExpanded = noCellExpanded
        tableView.tableFooterView = UIView()
    }

    /**
     Expand the cell at the index specified.
     
     - parameter index: The index of the cell to expand.
     */
    open func expandItemAtIndex(_ index : Int, parent: Int) {
        
        // the data of the childs for the specific parent cell.
        let currentSubItems = dataSource[parent].childs
        
        // update the state of the cell.
        dataSource[parent].state = .expanded
        
        // position to start to insert rows.
        var insertPos = index + 1
        
        let indexPaths = (0..<currentSubItems.count).map { _ -> IndexPath in
            let indexPath = IndexPath(row: insertPos, section: 0)
            insertPos += 1
            return indexPath
        }
        
        // insert the new rows
        tableView.insertRows(at: indexPaths, with: UITableViewRowAnimation.fade)
        
        // update the total of rows
        total += currentSubItems.count
    }
    
    /**
     Collapse the cell at the index specified.
     
     - parameter index: The index of the cell to collapse
     */
    open func collapseSubItemsAtIndex(_ index : Int, parent: Int) {
        
        var indexPaths = [IndexPath]()
        
        let numberOfChilds = dataSource[parent].childs.count
        
        // update the state of the cell.
        dataSource[parent].state = .collapsed
        
        guard index + 1 <= index + numberOfChilds else { return }
        
        // create an array of NSIndexPath with the selected positions
        indexPaths = (index + 1...index + numberOfChilds).map { IndexPath(row: $0, section: 0)}
        
        // remove the expanded cells
        tableView.deleteRows(at: indexPaths, with: UITableViewRowAnimation.fade)
        
        // update the total of rows
        total -= numberOfChilds
    }
    
    fileprivate func collapseSingle(_ parent: Int, _ index: Int) {
        // exist one cell expanded previously
        if lastCellExpanded != noCellExpanded {
            
            let (indexOfCellExpanded, parentOfCellExpanded) = lastCellExpanded
            
            collapseSubItemsAtIndex(indexOfCellExpanded, parent: parentOfCellExpanded)
            
            // cell tapped is below of previously expanded, then we need to update the index to expand.
            if parent > parentOfCellExpanded {
                let newIndex = index - dataSource[parentOfCellExpanded].childs.count
                expandItemAtIndex(newIndex, parent: parent)
                lastCellExpanded = (newIndex, parent)
            } else {
                expandItemAtIndex(index, parent: parent)
                lastCellExpanded = (index, parent)
            }
        } else {
            expandItemAtIndex(index, parent: parent)
            lastCellExpanded = (index, parent)
        }
    }
    
    /**
     Update the cells to expanded to collapsed state in case of allow severals cells expanded.
     
     - parameter parent: The parent of the cell
     - parameter index:  The index of the cell.
     */
    open func updateCells(_ parent: Int, index: Int) {
        
        switch (dataSource[parent].state) {
            
        case .expanded:
            collapseSubItemsAtIndex(index, parent: parent)
            lastCellExpanded = noCellExpanded
            
        case .collapsed:
            switch (numberOfCellsExpanded) {
            case .one:
                collapseSingle(parent, index)
            case .several:
                expandItemAtIndex(index, parent: parent)
            }
        }
    }
    
    fileprivate func locateParent(_ position: Int, _ index: Int, _ parent: Int, _ item: inout Parent) -> (parent: Int, isParentCell: Bool, actualPosition: Int) {
        // if it's a parent cell the indexes are equal.
        if position == index {
            return (parent, position == index, position)
        }
        
        item = dataSource[parent - 1]
        return (parent - 1, position == index, position - item.childs.count - 1)
    }
    
    fileprivate func processStateFor(_ item: inout Parent, _ position: inout Int, _ parent: inout Int, _ index: Int) {
        repeat {
            
            switch (item.state) {
            case .expanded:
                position += item.childs.count + 1
            case .collapsed:
                position += 1
            }
            
            parent += 1
            
            // if is not outside of dataSource boundaries
            if parent < dataSource.count {
                item = dataSource[parent]
            }
            
        } while (position < index)
    }
    
    /**
     Find the parent position in the initial list, if the cell is parent and the actual position in the actual list.
     
     - parameter index: The index of the cell
     
     - returns: A tuple with the parent position, if it's a parent cell and the actual position righ now.
     */
    open func findParent(_ index : Int) -> (parent: Int, isParentCell: Bool, actualPosition: Int) {
        
        var position = 0, parent = 0
        guard position < index else { return (parent, true, parent) }
        
        var item = dataSource[parent]
        processStateFor(&item, &position, &parent, index)
        
        return locateParent(position, index, parent, &item)
    }
}

extension AccordionTableViewController {
    
    // MARK: - UITableViewDataSource
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return total
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell!
        
        let (parent, isParentCell, actualPosition) = findParent(indexPath.row)
        
        if !isParentCell {
            cell = tableView.dequeueReusableCell(withIdentifier: childCellIdentifier, for: indexPath)
            cell.textLabel!.text = dataSource[parent].childs[indexPath.row - actualPosition - 1]
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: parentCellIdentifier, for: indexPath)
            cell.textLabel!.text = dataSource[parent].title
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let (parent, isParentCell, actualPosition) = findParent(indexPath.row)
        
        guard isParentCell else {
            NSLog("A child was tapped!!!")
            
            // The value of the child is indexPath.row - actualPosition - 1
            NSLog("The value of the child is \(dataSource[parent].childs[indexPath.row - actualPosition - 1])")
            
            return
        }
        
        tableView.beginUpdates()
        updateCells(parent, index: indexPath.row)
        tableView.endUpdates()
    }
    
    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return !findParent(indexPath.row).isParentCell ? 44.0 : 64.0
    }
}
