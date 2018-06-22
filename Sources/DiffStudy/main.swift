enum Direction {
    case down
    case right
}

func shortestEditScriptLength(old: String, new: String) -> Int {
    let old: [Character] = old.map { $0 }
    let new: [Character] = new.map { $0 }
    
    let maxD: Int = old.count + new.count
    
    var _largestXForK: [Int] = [Int].init(repeating: 0,
                                          count: max(2, maxD + 1))
    
    func largestX(forK k: Int) -> Int {
        var k = k
        if k < 0 { k += _largestXForK.count }
        return _largestXForK[k]
    }
    
    func setLargestX(_ x: Int, forK k: Int) {
        var k = k
        if k < 0 { k += _largestXForK.count }
        _largestXForK[k] = x
    }
    
    setLargestX(0, forK: 1)
    
    for d in 0...maxD {
        let minKForD: Int = -(d - 2 * max(0, d - new.count))
        let maxKForD: Int = d - 2 * max(0, d - old.count)
        
        for k in stride(from: minKForD, through: maxKForD, by: 2) {
            let direction: Direction = {
                if k == -d {
                    return .down
                }
                if k == d {
                    return .right
                }
                if largestX(forK: k - 1) < largestX(forK: k + 1) {
                    return .down
                } else {
                    return .right
                }
            }()
            
            var x: Int
            switch direction {
            case .down:
                x = largestX(forK: k + 1)
            case .right:
                x = largestX(forK: k - 1) + 1
            }
            var y = x - k
            
            while true {
                guard x < old.count, y < new.count else { break }
                if old[x] == new[y] {
                    x += 1
                    y += 1
                } else {
                    break
                }
            }
            setLargestX(x, forK: k)
            
            if x >= old.count && y >= new.count {
                return d
            }
        }
    }
    
    fatalError("never reach here")
}

enum Patch {
    case insert(oldIndex: Int, newIndex: Int)
    case delete(oldIndex: Int)
}

typealias Diff = [Patch]

class Box<T> {
    var value: T
    
    init(_ value: T) {
        self.value = value
    }
}

class Slice<T> {
    init(_ array: Box<[T]>, offset: Int, length: Int) {
        self.array = array
        self.offset = offset
        self.length = length
    }
    
    init(_ slice: Slice<T>, offset: Int, length: Int) {
        self.array = slice.array
        self.offset = slice.offset + offset
        self.length = length
    }
    
    var count: Int {
        return length
    }
    
    subscript(index: Int) -> T {
        get {
            return array.value[offset + index]
        }
        set {
            array.value[offset + index] = newValue
        }
    }
    
    let array: Box<[T]>
    let offset: Int
    let length: Int
}

func difference(between old: String, _ new: String) -> Diff {
    let old = Slice(Box(old.map { $0 }), offset: 0, length: old.count)
    let new = Slice(Box(new.map { $0 }), offset: 0, length: new.count)
    return difference(between: old, new)
}

enum ScanDirection {
    case forward
    case reverse
    
    static var allCases: [ScanDirection] {
        return [.forward, .reverse]
    }
}

func difference(between old: Slice<Character>, _ new: Slice<Character>) -> Diff {

    func recurse(_ i: Int, _ j: Int) -> Diff {
        let maxD = old.count + new.count
        let workSize = 2 * min(old.count, new.count) + 2
        
        if new.count == 0 {
            return (0..<old.count).map {
                Patch.delete(oldIndex: i + $0)
            }
        }
        
        if old.count == 0 {
            return (0..<new.count).map {
                Patch.insert(oldIndex: i, newIndex: j + $0)
            }
        }

        let w = old.count - new.count
        let storage0 = Box(Array<Int>(repeating: 0, count: workSize))
        let storage1 = Box(Array<Int>(repeating: 0, count: workSize))
        
        let hMax: Int = (maxD + 1) / 2
        
        for h in 0...hMax {
            for scanDirection in ScanDirection.allCases {
                let c: Box<Array<Int>>
                let d: Box<Array<Int>>
                let o: Int, m: Int
                
                switch scanDirection {
                case .forward:
                    c = storage0
                    d = storage1
                    o = 1
                    m = 1
                case .reverse:
                    c = storage1
                    d = storage0
                    o = 0
                    m = -1
                }
                
                let minK = -(h - 2 * max(0,h - old.count))
                let maxK = h - 2 * max(0, h - new.count) + 1
                
                for k in stride(from: minK, through: maxK, by: 2) {
                    
                }
            }
        }
        
        
    }
    
    return recurse(0, 0)
    
    
}


print(shortestEditScriptLength(old: "abcabba", new: "cbabac"))
