import Foundation

/// LogicOptimizer implements circuit optimization techniques for boolean expressions.
/// It focuses on minimizing the number of logic gates needed while maintaining functional equivalence.
public struct LogicOptimizer {
    /// Configuration for controlling optimization strategies
    public struct Configuration: Sendable {
        /// When true, uses K-map based optimization
        public let useKMap: Bool
        /// When true, considers don't care conditions for larger groups
        public let useDontCares: Bool
        /// When true, prefers AND gates over OR gates when cost is equal
        public let preferAndGates: Bool
        
        public init(
            useKMap: Bool = true,
            useDontCares: Bool = true,
            preferAndGates: Bool = true
        ) {
            self.useKMap = useKMap
            self.useDontCares = useDontCares
            self.preferAndGates = preferAndGates
        }
        
        public static let none = Configuration(
            useKMap: false,
            useDontCares: false,
            preferAndGates: true
        )
        
        public static let all = Configuration(
            useKMap: true,
            useDontCares: true,
            preferAndGates: true
        )
    }
    
    private let config: Configuration
    
    public init(configuration: Configuration = .all) {
        self.config = configuration
    }
    
    /// Optimizes a formula to minimize the number of required gates
    /// - Parameter formula: The formula to optimize
    /// - Returns: Optimized formula with minimal gate count
    public func optimize(_ formula: Formula) -> Formula {
        var optimizedExpression = formula.expression
        
        if config.useKMap {
            // Apply K-map optimization only
            optimizedExpression = applyKMapOptimization(optimizedExpression)
        } else {
            // Apply common factor extraction only if not using K-map
            optimizedExpression = extractCommonFactors(optimizedExpression)
        }
        
        return Formula(
            output: formula.output,
            expression: optimizedExpression,
            value: formula.value
        )
    }
    
    /// Applies K-map optimization to minimize gate count
    private func applyKMapOptimization(_ expression: Expression) -> Expression {
        // Create and fill K-map
        var kmap = createKMap(from: expression)
        
        // Handle don't care conditions if enabled
        if config.useDontCares {
            handleDontCares(&kmap)
        }
        
        // First check for common factors as they're simpler
        let commonFactorsResult = extractCommonFactors(expression)
        if commonFactorsResult.count == 1 || 
           (commonFactorsResult.count == 2 && commonFactorsResult[0].value == "~") {
            return commonFactorsResult
        }
        
        // Check for constant cases (all 0s or all 1s)
        let allZeros = kmap.allSatisfy { row in row.allSatisfy { $0 == .zero } }
        let allOnes = kmap.allSatisfy { row in row.allSatisfy { $0 == .one } }
        
        if allZeros {
            return [Token(value: "0", type: .Operand)]
        }
        if allOnes {
            return [Token(value: "1", type: .Operand)]
        }
        
        // Find optimal groups and convert to expression
        let groups = findOptimalGroups(in: kmap)
        return config.preferAndGates ? 
            optimizeForAndGates(groups) : 
            convertGroupsToExpression(groups)
    }
    
    /// Represents a cell in the K-map
    private enum KMapCell: Equatable {
        case zero      // Output is 0
        case one       // Output is 1
        case dontCare  // Output doesn't matter
    }
    
    /// Creates a K-map representation from an expression
    /// - Parameter expression: The expression to convert
    /// - Returns: 2D array representing K-map values
    private func createKMap(from expression: Expression) -> [[KMapCell]] {
        // Get unique variables and sort for consistent mapping
        let variables = extractVariables(from: expression)
        
        // Calculate dimensions ensuring balanced split
        let rows = 1 << (variables.count / 2)         // 2^(n/2) rows
        let cols = 1 << ((variables.count + 1) / 2)   // 2^((n+1)/2) columns
        
        // Initialize empty K-map
        var kmap = Array(repeating: Array(repeating: KMapCell.zero, count: cols), count: rows)
        
        // Fill K-map with values
        fillKMap(&kmap, expression: expression, variables: variables)
        
        return kmap
    }
    
    /// Extracts unique variables from an expression
    private func extractVariables(from expression: Expression) -> Set<String> {
        var variables = Set<String>()
        for token in expression where token.type == .Operand {
            variables.insert(token.value)
        }
        return variables
    }
    
    /// Fills K-map with values based on the expression
    private func fillKMap(_ kmap: inout [[KMapCell]], expression: Expression, variables: Set<String>) {
        let variableList = Array(variables).sorted()
        let rowVars = Array(variableList[..<(variableList.count/2)])
        let colVars = Array(variableList[(variableList.count/2)...])
        
        for row in 0..<kmap.count {
            for col in 0..<kmap[0].count {
                let rowBits = String(row, radix: 2)
                    .padding(toLength: rowVars.count, withPad: "0", startingAt: 0)
                let colBits = String(col, radix: 2)
                    .padding(toLength: colVars.count, withPad: "0", startingAt: 0)
                
                var assignments: [String: Bool] = [:]
                
                // Assign row variables
                for (var_, bit) in zip(rowVars, rowBits) {
                    assignments[var_] = (bit == "1")
                }
                
                // Assign column variables
                for (var_, bit) in zip(colVars, colBits) {
                    assignments[var_] = (bit == "1")
                }
                
                if evaluateExpression(expression, with: assignments) {
                    kmap[row][col] = .one
                }
            }
        }
    }
    
    /// Evaluates expression with given variable assignments
    private func evaluateExpression(_ expression: Expression, with assignments: [String: Bool]) -> Bool {
        var stack: [Bool] = []
        
        for token in expression {
            switch token.type {
            case .Operand:
                stack.append(assignments[token.value] ?? false)
            case .Operator:
                switch token.value {
                case "~": // NOT operation
                    if let last = stack.popLast() {
                        stack.append(!last)
                    }
                case "*": // AND operation
                    if let b = stack.popLast(), let a = stack.popLast() {
                        stack.append(a && b)
                    }
                case "+": // OR operation
                    if let b = stack.popLast(), let a = stack.popLast() {
                        stack.append(a || b)
                    }
                default:
                    break
                }
            default:
                break
            }
        }
        
        return stack.last ?? false
    }
    
    /// Represents a group of cells in K-map that can be combined
    private struct Group {
        let cells: [(row: Int, col: Int)]
        let variables: [Token]
    }
    
    /// Finds optimal groupings in K-map
    /// Rules from K-map documentation:
    /// 1. Groups must contain only 1's inside
    /// 2. Groups must be rectangles (can wrap around edges)
    /// 3. Rectangle sides must be powers of 2 (1, 2, or 4)
    /// 4. Every 1 must be covered by at least one group
    /// 5. Use as few groups as possible
    /// 6. Each group should be as large as possible
    private func findOptimalGroups(in kmap: [[KMapCell]]) -> [Group] {
        var workingKmap = kmap
        if config.useDontCares {
            handleDontCares(&workingKmap)
        }
        
        // Check for row patterns first
        if let rowGroup = findRowPattern(in: workingKmap) {
            return [rowGroup]
        }
        
        // Check for column patterns
        if let colGroup = findColumnPattern(in: workingKmap) {
            return [colGroup]
        }
        
        // Try standard groupings
        let groupSizes = [(4,4), (4,2), (2,4), (2,2), (2,1), (1,2), (1,1)]
        
        for (height, width) in groupSizes {
            for row in 0..<workingKmap.count {
                for col in 0..<workingKmap[0].count {
                    if workingKmap[row][col] == .one {
                        if let group = tryCreateGroup(
                            at: row,
                            col: col,
                            height: height,
                            width: width,
                            in: workingKmap,
                            covered: []
                        ) {
                            return [group]
                        }
                    }
                }
            }
        }
        
        return []
    }
    
    /// Handles don't care conditions in K-map optimization
    private func handleDontCares(_ kmap: inout [[KMapCell]]) {
        if !config.useDontCares { return }
        
        // Convert don't cares to ones if they help form larger groups
        for row in 0..<kmap.count {
            for col in 0..<kmap[0].count {
                if kmap[row][col] == .dontCare {
                    // Check if converting to one would allow larger group
                    kmap[row][col] = .one
                    if wouldFormLargerGroup(at: row, col: col, in: kmap) {
                        continue // Keep as one
                    }
                    kmap[row][col] = .dontCare // Reset if not helpful
                }
            }
        }
    }
    
    /// Checks if a cell would help form a larger group if set to one
    private func wouldFormLargerGroup(at row: Int, col: Int, in kmap: [[KMapCell]]) -> Bool {
        // Check adjacent cells (including wrapped positions)
        let adjacentPositions = [
            ((row - 1 + kmap.count) % kmap.count, col),
            ((row + 1) % kmap.count, col),
            (row, (col - 1 + kmap[0].count) % kmap[0].count),
            (row, (col + 1) % kmap[0].count)
        ]
        
        // Count adjacent ones
        let adjacentOnes = adjacentPositions.filter { pos in
            kmap[pos.0][pos.1] == .one
        }.count
        
        return adjacentOnes >= 2 // Would help form larger group
    }
    
    /// Finds patterns where all 1's are in specific rows
    private func findRowPattern(in kmap: [[KMapCell]]) -> Group? {
        let rows = kmap.count
        let cols = kmap[0].count
        let rowBits = Int(log2(Double(rows)))
        
        // Find rows with all ones
        var rowsWithAllOnes: [Int] = []
        for row in 0..<rows {
            if kmap[row].allSatisfy({ $0 == .one }) {
                rowsWithAllOnes.append(row)
            }
        }
        
        if !rowsWithAllOnes.isEmpty {
            var variables: [Token] = []
            
            // Check each bit position
            for bit in 0..<rowBits {
                let mask = 1 << bit
                let bitValues = Set(rowsWithAllOnes.map { ($0 & mask) != 0 })
                
                // If bit is constant across all matching rows
                if bitValues.count == 1 {
                    if !variables.isEmpty {
                        variables.append(Token(value: "*", type: .Operator))
                    }
                    if !bitValues.contains(true) {
                        variables.append(Token(value: "~", type: .Operator))
                    }
                    variables.append(Token(value: "in\(bit + 1)", type: .Operand))
                }
            }
            
            // Create cells for the group
            let cells = rowsWithAllOnes.flatMap { row in
                (0..<cols).map { col in (row, col) }
            }
            
            return Group(cells: cells, variables: variables)
        }
        
        return nil
    }
    
    /// Finds patterns where all 1's are in specific columns
    private func findColumnPattern(in kmap: [[KMapCell]]) -> Group? {
        let rows = kmap.count
        let cols = kmap[0].count
        let colBits = Int(log2(Double(cols)))
        
        // Find columns with all ones
        var colsWithAllOnes: [Int] = []
        for col in 0..<cols {
            if (0..<rows).allSatisfy({ row in kmap[row][col] == .one }) {
                colsWithAllOnes.append(col)
            }
        }
        
        if !colsWithAllOnes.isEmpty {
            var variables: [Token] = []
            
            // Check each bit position
            for bit in 0..<colBits {
                let mask = 1 << bit
                let bitValues = Set(colsWithAllOnes.map { ($0 & mask) != 0 })
                
                // If bit is constant across all matching columns
                if bitValues.count == 1 {
                    if !variables.isEmpty {
                        variables.append(Token(value: "*", type: .Operator))
                    }
                    if !bitValues.contains(true) {
                        variables.append(Token(value: "~", type: .Operator))
                    }
                    variables.append(Token(value: "in\(bit + Int(log2(Double(rows))) + 1)", type: .Operand))
                }
            }
            
            // Create cells for the group
            let cells = colsWithAllOnes.flatMap { col in
                (0..<rows).map { row in (row, col) }
            }
            
            return Group(cells: cells, variables: variables)
        }
        
        return nil
    }
    
    /// Determines which variables are relevant for a group
    private func determineGroupVariables(cells: [(row: Int, col: Int)], kmapSize: (rows: Int, cols: Int)) -> [Token] {
        var variables: [Token] = []
        let rowBits = Int(log2(Double(kmapSize.rows)))
        let colBits = Int(log2(Double(kmapSize.cols)))
        
        // Get unique row and column values
        let rows = Set(cells.map { $0.row })
        let cols = Set(cells.map { $0.col })
        
        // Process row variables (first half of variables)
        for bit in 0..<rowBits {
            let mask = 1 << bit
            let values = rows.map { ($0 & mask) >> bit }
            
            // If bit is constant across all rows in group
            if values.count == 1 {
                if !variables.isEmpty {
                    variables.append(Token(value: "*", type: .Operator))
                }
                // Add NOT if constant is 0
                if values.first! == 0 {
                    variables.append(Token(value: "~", type: .Operator))
                }
                variables.append(Token(value: "in\(bit + 1)", type: .Operand))
            }
        }
        
        // Process column variables (second half of variables)
        for bit in 0..<colBits {
            let mask = 1 << bit
            let values = cols.map { ($0 & mask) >> bit }
            
            // If bit is constant across all columns in group
            if values.count == 1 {
                if !variables.isEmpty {
                    variables.append(Token(value: "*", type: .Operator))
                }
                // Add NOT if constant is 0
                if values.first! == 0 {
                    variables.append(Token(value: "~", type: .Operator))
                }
                variables.append(Token(value: "in\(bit + rowBits + 1)", type: .Operand))
            }
        }
        
        return variables
    }
    
    /// Attempts to create a group with specified dimensions
    private func tryCreateGroup(
        at row: Int, 
        col: Int, 
        height: Int, 
        width: Int, 
        in kmap: [[KMapCell]], 
        covered: Set<String>
    ) -> Group? {
        var cells: [(row: Int, col: Int)] = []
        
        // Check all cells in potential group
        for r in 0..<height {
            for c in 0..<width {
                let actualRow = (row + r) % kmap.count
                let actualCol = (col + c) % kmap[0].count
                let cellKey = "\(actualRow),\(actualCol)"
                
                if covered.contains(cellKey) || kmap[actualRow][actualCol] != .one {
                    return nil
                }
                cells.append((actualRow, actualCol))
            }
        }
        
        // Create variables for this group
        let groupVars = determineGroupVariables(cells: cells, kmapSize: (kmap.count, kmap[0].count))
        if !groupVars.isEmpty {
            return Group(cells: cells, variables: groupVars)
        }
        
        return nil
    }
    
    /// Optimizes expression to minimize AND gates
    private func optimizeForAndGates(_ groups: [Group]) -> Expression {
        guard !groups.isEmpty else { return [] }
        
        // For single group, return its variables directly
        if groups.count == 1 {
            return groups[0].variables
        }
        
        // Look for common variables
        let commonVars = findCommonVariablesAcrossGroups(groups)
        if commonVars.isEmpty {
            return createBasicExpression(from: groups)
        }
        
        var expression: Expression = []
        
        // Add common variables first
        for (index, var_) in commonVars.enumerated() {
            if index > 0 {
                expression.append(Token(value: "*", type: .Operator))
            }
            if var_.hasPrefix("~") {
                expression.append(Token(value: "~", type: .Operator))
                expression.append(Token(value: String(var_.dropFirst()), type: .Operand))
            } else {
                expression.append(Token(value: var_, type: .Operand))
            }
        }
        
        // Add remaining terms if any
        let remainingTerms = extractRemainingTerms(groups, excluding: commonVars)
        if !remainingTerms.isEmpty {
            expression.append(Token(value: "*", type: .Operator))
            expression.append(Token(value: "(", type: .BracketOpen))
            
            for (index, term) in remainingTerms.enumerated() {
                if index > 0 {
                    expression.append(Token(value: "+", type: .Operator))
                }
                expression.append(contentsOf: term)
            }
            
            expression.append(Token(value: ")", type: .BracketClose))
        }
        
        return expression
    }
    
    /// Creates a basic expression from groups without optimization
    private func createBasicExpression(from groups: [Group]) -> Expression {
        var expression: Expression = []
        
        for (index, group) in groups.enumerated() {
            if index > 0 {
                expression.append(Token(value: "+", type: .Operator))
            }
            
            let needsParentheses = group.variables.count > 1
            if needsParentheses {
                expression.append(Token(value: "(", type: .BracketOpen))
            }
            
            for (varIndex, token) in group.variables.enumerated() {
                if varIndex > 0 && token.type == .Operand {
                    expression.append(Token(value: "*", type: .Operator))
                }
                expression.append(token)
            }
            
            if needsParentheses {
                expression.append(Token(value: ")", type: .BracketClose))
            }
        }
        
        return expression
    }
    
    /// Converts groups to expression with OR preference
    private func convertGroupsToExpression(_ groups: [Group]) -> Expression {
        if !config.preferAndGates {
            return createBasicExpression(from: groups)
        }
        return optimizeForAndGates(groups)
    }
    
    /// Finds variables that appear in all groups
    /// 
    /// Used to identify common factors that can be extracted to minimize gates.
    /// Only considers variables that appear with consistent polarity (normal or negated)
    /// across all groups.
    /// 
    /// Example:
    /// Groups: [(A*B), (A*C)] -> common variable: A
    /// Groups: [(~A*B), (~A*C)] -> common variable: ~A
    private func findCommonVariablesAcrossGroups(_ groups: [Group]) -> Set<String> {
        guard !groups.isEmpty else { return [] }
        
        // Get variables from first group
        var commonVars = extractVariablesFromGroup(groups[0])
        
        // Intersect with variables from other groups
        for group in groups.dropFirst() {
            let groupVars = extractVariablesFromGroup(group)
            commonVars = commonVars.intersection(groupVars)
        }
        
        return commonVars
    }
    
    /// Extracts variables from a group's variables array
    /// 
    /// Processes the tokens in a group to identify unique variables,
    /// handling both normal and negated forms.
    /// 
    /// Note: This method ignores operators other than NOT when
    /// collecting variables.
    private func extractVariablesFromGroup(_ group: Group) -> Set<String> {
        var variables = Set<String>()
        var isNegated = false
        
        for token in group.variables {
            switch token.type {
            case .Operand:
                let varName = isNegated ? "~\(token.value)" : token.value
                variables.insert(varName)
                isNegated = false
            case .Operator where token.value == "~":
                isNegated = true
            default:
                break
            }
        }
        
        return variables
    }
    
    /// Creates variables for a set of rows in K-map
    /// - Parameters:
    ///   - rows: Array of row indices
    ///   - rowBits: Number of bits used for row addressing
    /// - Returns: Array of tokens representing the variables
    private func createVariablesForRows(_ rows: [Int], rowBits: Int) -> [Token] {
        var variables: [Token] = []
        
        // Check each bit position
        for bit in 0..<rowBits {
            let mask = 1 << bit
            let bitValues = Set(rows.map { ($0 & mask) != 0 })
            
            // If bit is constant across all rows
            if bitValues.count == 1 {
                if !variables.isEmpty {
                    variables.append(Token(value: "*", type: .Operator))
                }
                // Add NOT if constant is 0
                if !bitValues.contains(true) {
                    variables.append(Token(value: "~", type: .Operator))
                }
                variables.append(Token(value: "in\(bit + 1)", type: .Operand))
            }
        }
        
        return variables
    }
    
    /// Extracts common factors from the expression
    private func extractCommonFactors(_ expression: Expression) -> Expression {
        var terms: [[Token]] = []
        var currentTerm: [Token] = []
        var bracketCount = 0
        
        // Split expression into terms
        for token in expression {
            if token.type == .BracketOpen {
                bracketCount += 1
            } else if token.type == .BracketClose {
                bracketCount -= 1
            }
            
            if token.value == "+" && bracketCount == 0 {
                if !currentTerm.isEmpty {
                    terms.append(currentTerm)
                    currentTerm = []
                }
            } else {
                currentTerm.append(token)
            }
        }
        if !currentTerm.isEmpty {
            terms.append(currentTerm)
        }
        
        // Find common variables across all terms
        var commonVars: [(variable: String, isNegated: Bool)] = []
        if let firstTerm = terms.first {
            var isNegated = false
            
            // Extract variables from first term
            for token in firstTerm {
                switch token.type {
                case .Operand:
                    commonVars.append((token.value, isNegated))
                    isNegated = false
                case .Operator where token.value == "~":
                    isNegated = true
                default:
                    break
                }
            }
            
            // Check other terms for common variables
            for term in terms.dropFirst() {
                var termVars: [(variable: String, isNegated: Bool)] = []
                isNegated = false
                
                for token in term {
                    switch token.type {
                    case .Operand:
                        termVars.append((token.value, isNegated))
                        isNegated = false
                    case .Operator where token.value == "~":
                        isNegated = true
                    default:
                        break
                    }
                }
                
                // Keep only variables that appear with same negation in all terms
                commonVars = commonVars.filter { commonVar in
                    termVars.contains { termVar in
                        termVar.variable == commonVar.variable && 
                        termVar.isNegated == commonVar.isNegated
                    }
                }
            }
        }
        
        // If we found common variables, create simplified expression
        if !commonVars.isEmpty {
            var result: Expression = []
            
            for (index, var_) in commonVars.enumerated() {
                if index > 0 {
                    result.append(Token(value: "*", type: .Operator))
                }
                
                if var_.isNegated {
                    result.append(Token(value: "~", type: .Operator))
                }
                result.append(Token(value: var_.variable, type: .Operand))
            }
            
            return result
        }
        
        return expression
    }
    
    /// Extracts remaining terms after removing common variables
    /// - Parameters:
    ///   - groups: Array of groups to process
    ///   - commonVars: Set of common variables to exclude
    /// - Returns: Array of remaining terms (each term is an array of tokens)
    private func extractRemainingTerms(_ groups: [Group], excluding commonVars: Set<String>) -> [[Token]] {
        return groups.map { group in
            var termTokens: [Token] = []
            var isNegated = false
            
            for token in group.variables {
                switch token.type {
                case .Operand:
                    let varName = isNegated ? "~\(token.value)" : token.value
                    if !commonVars.contains(varName) {
                        if isNegated {
                            termTokens.append(Token(value: "~", type: .Operator))
                        }
                        termTokens.append(token)
                    }
                    isNegated = false
                case .Operator where token.value == "~":
                    isNegated = true
                default:
                    break
                }
            }
            
            return termTokens
        }.filter { !$0.isEmpty }
    }
} 
