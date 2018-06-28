public enum PatchItem {
    case insert(oldIndex: Int, newIndex: Int)
    case delete(oldIndex: Int)
    
    var oldIndex: Int {
        switch self {
        case .insert(oldIndex: let x, newIndex: _),
             .delete(oldIndex: let x): return x
        }
    }
}

public typealias Patch = [PatchItem]

public func difference(old: String, new: String) -> Patch {
    let old = Slice(elements: Box(old.map { $0 }), offset: 0, count: old.count)
    let new = Slice(elements: Box(new.map { $0 }), offset: 0, count: new.count)
    return difference(old: old, new: new)
}

internal class Box<T> {
    public var value: T
    public init(_ value: T) {
        self.value = value
    }
}

internal class Slice {
    public var elements: Box<[Character]>
    public var offset: Int
    public var count: Int
    
    public init(elements: Box<[Character]>,
                offset: Int,
                count: Int)
    {
        precondition(0 <= offset)
        precondition(0 <= count)
        precondition(offset + count <= elements.value.count)
        
        self.elements = elements
        self.offset = offset
        self.count = count
    }
    
    public subscript(index: Int) -> Character {
        get {
            return elements.value[offset + index]
        }
    }
    
    public subscript(range: Range<Int>) -> Slice {
        get {
            return Slice(elements: elements,
                         offset: offset + range.lowerBound,
                         count: range.count)
        }
    }
}

internal class ProgressTable {
    public var buffer: [Int]
    
    public init(size: Int) {
        self.buffer = Array(repeating: 0, count: size)
    }
    
    public var size: Int {
        return buffer.count
    }
    
    public subscript(k k: Int) -> Int {
        get {
            var k = k
            k %= size
            if k < 0 {
                k += size
            }
            return buffer[k]
        }
        set {
            var k = k
            k %= size
            if k < 0 {
                k += size
            }
            buffer[k] = newValue
        }
    }
}

internal enum ForwardDirection {
    case down
    case right
}
internal enum BackwardDirection {
    case up
    case left
}

private func difference(old: Slice, new: Slice) -> Patch {
    func recurse(old: Slice, new: Slice) -> Patch {
        if new.count == 0 {
            return (0..<old.count).map { (i: Int) -> PatchItem in
                return PatchItem.delete(oldIndex: old.offset + i)
            }
        }
        
        if old.count == 0 {
            return (0..<new.count).map { (i: Int) -> PatchItem in
                return PatchItem.insert(oldIndex: old.offset, newIndex: new.offset + i)
            }
        }
        
        let maxDistance: Int = old.count + new.count
        let tableSize: Int = 2 * min(old.count, new.count) + 1
        let lengthDiff = old.count - new.count
        
        func reverse(k: Int) -> Int {
            return lengthDiff - k
        }
        
        let forwardTable = ProgressTable(size: tableSize)
        let backwardTable = ProgressTable(size: tableSize)
        
        let stepNum: Int = (maxDistance + 1) / 2 + 1
        
        for step in 0..<stepNum {
            let minK: Int = {
                if step <= new.count {
                    return -step
                } else {
                    return -(new.count - (step - new.count))
                }
            }()
            
            let maxK: Int = {
                if step <= old.count {
                    return step
                } else {
                    return old.count - (step - old.count)
                }
            }()
            
            // forward
            do {
                for forwardK in stride(from: minK, through: maxK, by: 2) {
                    let direction: ForwardDirection = {
                        if forwardK == -step {
                           return .down
                        }
                        if forwardK == step {
                            return .right
                        }
                        if forwardTable[k: forwardK - 1] < forwardTable[k: forwardK + 1] {
                            return .down
                        } else {
                            return .right
                        }
                    }()
                    
                    let snakeStartX: Int = {
                        switch direction {
                        case .down:
                            return forwardTable[k: forwardK + 1]
                        case .right:
                            return forwardTable[k: forwardK - 1] + 1
                        }
                    }()
                    let snakeStartY: Int = snakeStartX - forwardK
                    
                    var snakeEndX = snakeStartX
                    var snakeEndY = snakeStartY
                    
                    while snakeEndX < old.count, snakeEndY < new.count {
                        if old[snakeEndX] == new[snakeEndY] {
                            snakeEndX += 1
                            snakeEndY += 1
                        } else {
                            break
                        }
                    }
                    
                    forwardTable[k: forwardK] = snakeEndX
                    
                    let backwardK = reverse(k: forwardK)
                    
                    if maxDistance % 2 == 1 {
                        if -(step-1) <= backwardK, backwardK <= (step-1),
                            forwardTable[k: forwardK] + backwardTable[k: backwardK] >= old.count
                        {
                            return difference(old: old[0..<snakeStartX], new: new[0..<snakeStartY]) +
                            difference(old: old[snakeEndX..<old.count], new: new[snakeEndY..<new.count])
                        }
                    }
                }
            }
            
            // back
            do {
                for backwardK in stride(from: minK, through: maxK, by: 2) {
                    let direction: BackwardDirection = {
                        if backwardK == -step {
                            return .up
                        }
                        if backwardK == step {
                            return .left
                        }
                        if backwardTable[k: backwardK - 1] < backwardTable[k: backwardK + 1] {
                            return .up
                        } else {
                            return .left
                        }
                    }()
                    
                    let snakeStartX: Int = {
                        switch direction {
                        case .up:
                            return backwardTable[k: backwardK + 1]
                        case .left:
                            return backwardTable[k: backwardK - 1] + 1
                        }
                    }()
                    let snakeStartY: Int = snakeStartX - backwardK
                    
                    var snakeEndX = snakeStartX
                    var snakeEndY = snakeStartY
                    
                    while snakeEndX < old.count, snakeEndY < new.count {
                        if old[old.count - 1 - snakeEndX] == new[new.count - 1 - snakeEndY] {
                            snakeEndX += 1
                            snakeEndY += 1
                        } else {
                            break
                        }
                    }
                    
                    backwardTable[k: backwardK] = snakeEndX
                    
                    let forwardK = reverse(k: backwardK)
                    
                    if maxDistance % 2 == 0 {
                        if -step <= forwardK, forwardK <= step,
                            forwardTable[k: forwardK] + backwardTable[k: backwardK] >= old.count
                        {
                            return difference(old: old[0..<(old.count - snakeEndX)],
                                              new: new[0..<(new.count - snakeEndY)]) +
                                difference(old: old[(old.count - snakeStartX)..<old.count],
                                           new: new[(new.count - snakeStartY)..<new.count])
                        }
                    }
                }
            }
        }
        
        fatalError("never reach here")
    }
    return recurse(old: old, new: new)
}

func apply(patch: Patch, old: String, new: String) -> String {
    let old = old.map { $0 }
    let new = new.map { $0 }
    
    var ret: [Character] = []
    
    var oldIndex = 0
    for item in patch {
        while oldIndex < item.oldIndex {
            ret.append(old[oldIndex])
            oldIndex += 1
        }
        switch item {
        case .delete:
            oldIndex += 1
        case .insert(oldIndex: _, newIndex: let newIndex):
            ret.append(new[newIndex])
        }
    }
    while oldIndex < old.count {
        ret.append(old[oldIndex])
        oldIndex += 1
    }
    return String(ret)
}

let old = "abcabba"
let new = "cbabac"
let patch = difference(old: old, new: new)
let check = apply(patch: patch, old: old, new: new)
print(new == check)
