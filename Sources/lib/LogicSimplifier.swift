/// LogicSimplifier applies boolean algebra laws to simplify logical expressions.
/// It can apply various simplification rules like:
/// - Idempotent Law (A + A = A)
/// - Absorption Law (A + AB = A)
/// - Complement Law (A + ~A = 1)
/// - De Morgan's Laws (~(A + B) = ~A * ~B)
public struct LogicSimplifier {
    /// Configuration for controlling which simplification rules to apply
    public struct Configuration: Sendable {
        public let useAbsorptionLaw: Bool
        public let useIdempotentLaw: Bool
        public let useComplementLaw: Bool
        public let useDeMorgansLaw: Bool
        
        /// Creates a configuration with specified rules enabled/disabled
        /// - Parameters:
        ///   - useAbsorptionLaw: Enable absorption law (A + AB = A)
        ///   - useIdempotentLaw: Enable idempotent law (A + A = A)
        ///   - useComplementLaw: Enable complement law (A + ~A = 1)
        ///   - useDeMorgansLaw: Enable De Morgan's laws
        public init(
            useAbsorptionLaw: Bool,
            useIdempotentLaw: Bool,
            useComplementLaw: Bool,
            useDeMorgansLaw: Bool
        ) {
            self.useAbsorptionLaw = useAbsorptionLaw
            self.useIdempotentLaw = useIdempotentLaw
            self.useComplementLaw = useComplementLaw
            self.useDeMorgansLaw = useDeMorgansLaw
        }
        
        /// Configuration with no simplification rules enabled
        public static let none = Configuration(
            useAbsorptionLaw: false,
            useIdempotentLaw: false,
            useComplementLaw: false,
            useDeMorgansLaw: false
        )
        
        /// Configuration with all simplification rules enabled
        public static let all = Configuration(
            useAbsorptionLaw: true,
            useIdempotentLaw: true,
            useComplementLaw: true,
            useDeMorgansLaw: true
        )
    }
    
    private let config: Configuration
    
    /// Creates a LogicSimplifier with specified configuration
    /// - Parameter configuration: Rules configuration, defaults to all rules enabled
    public init(configuration: Configuration = .all) {
        self.config = configuration
    }
    
    /// Simplifies a logical formula using configured optimization techniques
    /// - Parameter formula: The formula to simplify
    /// - Returns: Simplified formula with the same output variable
    public func simplify(_ formula: Formula) -> Formula {
        var simplifiedExpression = formula.expression
        
        // Apply each enabled simplification rule in sequence
        if config.useIdempotentLaw {
            simplifiedExpression = applyIdempotentLaw(simplifiedExpression)
        }
        
        if config.useAbsorptionLaw {
            simplifiedExpression = applyAbsorptionLaw(simplifiedExpression)
        }
        
        if config.useComplementLaw {
            simplifiedExpression = applyComplementLaw(simplifiedExpression)
        }
        
        if config.useDeMorgansLaw {
            simplifiedExpression = applyDeMorgansLaw(simplifiedExpression)
        }
        
        return Formula(
            output: formula.output,
            expression: simplifiedExpression,
            value: formula.value
        )
    }
    
    /// Applies idempotent law: A + A = A, A * A = A
    /// Removes duplicate terms in sum-of-products form
    private func applyIdempotentLaw(_ expression: Expression) -> Expression {
        // Split expression into terms (parts separated by +)
        var terms: [[Token]] = []
        var currentTerm: [Token] = []
        var bracketCount = 0
        
        // Track bracket depth to properly split terms
        for token in expression {
            if token.type == .BracketOpen {
                bracketCount += 1
            } else if token.type == .BracketClose {
                bracketCount -= 1
            }
            
            // Only split on + when not inside brackets
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
        
        // Remove duplicate terms by converting to strings for comparison
        let uniqueTerms = Array(Set(terms.map { term in
            term.map { $0.value }.joined()
        })).map { termString in
            terms.first { term in
                term.map { $0.value }.joined() == termString
            }!
        }
        
        // Reconstruct expression with unique terms
        return uniqueTerms.enumerated().flatMap { index, term in
            index == 0 ? term : [Token(value: "+", type: .Operator)] + term
        }
    }
    
    /// Applies absorption law: A + (A * B) = A
    /// Removes terms that are absorbed by simpler terms
    private func applyAbsorptionLaw(_ expression: Expression) -> Expression {
        // Split the expression into terms (parts separated by +)
        var terms: [[Token]] = []
        var currentTerm: [Token] = []
        var bracketCount = 0
        
        // Split while respecting bracket depth
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
        
        var simplifiedTerms = terms
        
        // Compare each pair of terms for absorption
        for i in 0..<simplifiedTerms.count {
            for j in (i + 1)..<simplifiedTerms.count {
                let vars1 = getVariables(from: simplifiedTerms[i])
                let vars2 = getVariables(from: simplifiedTerms[j])
                
                // If one term's variables are subset of another's,
                // the term with more variables can be removed
                if vars1.isSubset(of: vars2) {
                    simplifiedTerms[j] = []  // Mark for removal
                } else if vars2.isSubset(of: vars1) {
                    simplifiedTerms[i] = []  // Mark for removal
                }
            }
        }
        
        // Remove marked terms and reconstruct
        simplifiedTerms = simplifiedTerms.filter { !$0.isEmpty }
        return simplifiedTerms.enumerated().flatMap { index, term in
            index == 0 ? term : [Token(value: "+", type: .Operator)] + term
        }
    }
    
    /// Extracts variables from a term, handling NOT operators
    /// Returns a set of variable names, with "~" prefix for negated variables
    private func getVariables(from term: [Token]) -> Set<String> {
        var variables: Set<String> = []
        var isNegated = false
        var inBrackets = false
        
        for token in term {
            switch token.type {
            case .Operand:
                let varName = token.value
                variables.insert(isNegated ? "~\(varName)" : varName)
                isNegated = false
            case .Operator where token.value == "~":
                isNegated = true
            case .BracketOpen:
                inBrackets = true
            case .BracketClose:
                inBrackets = false
            default:
                break
            }
        }
        
        return variables
    }
    
    /// Applies complement law: A * ~A = 0, A + ~A = 1
    /// TODO: Implement complement law simplification
    private func applyComplementLaw(_ expression: Expression) -> Expression {
        // Future implementation will handle:
        // - Finding complementary terms (A and ~A)
        // - Simplifying based on AND/OR operations
        return expression
    }
    
    /// Applies De Morgan's laws: ~(A + B) = ~A * ~B, ~(A * B) = ~A + ~B
    /// TODO: Implement De Morgan's law transformations
    private func applyDeMorgansLaw(_ expression: Expression) -> Expression {
        // Future implementation will handle:
        // - Finding NOT operations over brackets
        // - Distributing NOT to inner terms
        // - Swapping AND/OR operators
        return expression
    }
} 
