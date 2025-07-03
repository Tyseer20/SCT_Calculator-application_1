import 'package:flutter/material.dart';

void main() {
  runApp(const CalcMateApp());
}

class CalcMateApp extends StatelessWidget {
  const CalcMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalcMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String input = '';
  String result = '';

  // Helper to tokenize the expression string into numbers and operators
  List<String> _tokenizeExpression(String expression) {
    final List<String> tokens = [];
    String currentNumber = '';

    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if (char == '+' || char == '-' || char == '*' || char == '/') {
        if (currentNumber.isNotEmpty) {
          tokens.add(currentNumber);
          currentNumber = '';
        }
        // Special handling for leading negative sign or negative number after an operator
        // e.g., "-5" or "2*-3"
        if (char == '-' && (tokens.isEmpty || ['+', '-', '*', '/'].contains(tokens.last))) {
          currentNumber = '-'; // Start collecting a negative number
        } else {
          tokens.add(char);
        }
      } else if (char == '.') {
        currentNumber += char;
      } else if (char.codeUnitAt(0) >= '0'.codeUnitAt(0) && char.codeUnitAt(0) <= '9'.codeUnitAt(0)) {
        currentNumber += char;
      } else {
        throw FormatException("Invalid character: $char");
      }
    }
    if (currentNumber.isNotEmpty) {
      tokens.add(currentNumber);
    }
    return tokens;
  }

  // Helper to evaluate the tokenized expression respecting operator precedence
  double _evaluateTokens(List<String> tokens) {
    // Make a mutable copy for in-place modifications during evaluation
    List<String> processingTokens = List<String>.from(tokens);

    // First pass: Multiplication and Division
    for (int i = 0; i < processingTokens.length; i++) {
      if (processingTokens[i] == '*' || processingTokens[i] == '/') {
        if (i == 0 || i + 1 >= processingTokens.length) {
          throw const FormatException("Invalid expression format.");
        }
        double num1 = double.parse(processingTokens[i - 1]);
        double num2 = double.parse(processingTokens[i + 1]);
        double res;
        if (processingTokens[i] == '*') {
          res = num1 * num2;
        } else {
          if (num2 == 0) {
            throw Exception("Division by zero");
          }
          res = num1 / num2;
        }
        processingTokens.replaceRange(i - 1, i + 2, [res.toString()]);
        i -= 2; // Adjust index after modifying list to re-evaluate from the start of the modified segment
      }
    }

    // Second pass: Addition and Subtraction
    if (processingTokens.isEmpty) {
      throw const FormatException("Empty expression after first pass.");
    }
    if (processingTokens.length == 1) {
      // If only one number remains after the first pass (e.g., "5", "2*3" -> "6")
      return double.parse(processingTokens[0]);
    }

    // Validate format for second pass: Should be number, operator, number, operator, ...
    if (processingTokens.length % 2 == 0) {
      throw const FormatException("Invalid expression format (missing operand).");
    }

    double currentResult = double.parse(processingTokens[0]);
    for (int i = 1; i < processingTokens.length; i += 2) {
      String op = processingTokens[i];
      double num = double.parse(processingTokens[i + 1]);
      if (op == '+') {
        currentResult += num;
      } else if (op == '-') {
        currentResult -= num;
      } else {
        throw FormatException("Unexpected operator '$op' after first pass.");
      }
    }
    return currentResult;
  }

  void buttonPressed(String text) {
    setState(() {
      if (text == 'C') {
        input = '';
        result = '';
      } else if (text == '=') {
        try {
          if (input.isEmpty) {
            result = '';
            return;
          }

          // Basic input validation before full evaluation
          if (input.endsWith('+') || input.endsWith('-') ||
              input.endsWith('×') || input.endsWith('÷')) {
            result = 'Error'; // Cannot end with an operator
            return;
          }
          if (input.startsWith('×') || input.startsWith('÷')) {
            result = 'Error'; // Cannot start with multiplication or division
            return;
          }

          // Replace display operators with internal ones for evaluation
          String expressionToEvaluate = input.replaceAll('×', '*').replaceAll('÷', '/');

          List<String> tokens = _tokenizeExpression(expressionToEvaluate);
          double eval = _evaluateTokens(tokens);

          // Format result: remove trailing .0 if it's an integer, otherwise limit decimal places
          String formattedResult = eval.toStringAsFixed(5); // Use a fixed number of decimal places for precision
          if (formattedResult.contains('.')) {
            formattedResult = formattedResult.replaceAll(RegExp(r'0*$'), ''); // Remove trailing zeros
            if (formattedResult.endsWith('.')) {
              formattedResult = formattedResult.substring(0, formattedResult.length - 1); // Remove trailing decimal if only '.' remains
            }
          }
          result = formattedResult;
        } on FormatException catch (_) {
          result = 'Error'; // Don't expose internal format messages to the user
        } catch (_) {
          result = 'Error';
        }
      } else {
        // Determine if the current last char in input is an operator and if the new char is an operator
        bool isLastCharOperator = input.isNotEmpty && ['+', '-', '×', '÷'].contains(input.substring(input.length - 1));
        bool isNewCharOperator = ['+', '-', '×', '÷'].contains(text);

        if (text == '.') {
          // Prevent multiple decimal points in a single number
          int lastOperatorIndex = -1;
          for (int i = input.length - 1; i >= 0; i--) {
            if (['+', '-', '×', '÷'].contains(input[i])) {
              lastOperatorIndex = i;
              break;
            }
          }
          String currentNumberSegment = input.substring(lastOperatorIndex + 1);
          if (currentNumberSegment.contains('.')) {
            return; // Already has a decimal point in the current number segment
          }
          // If input is empty or ends with an operator, automatically add '0.' before the decimal
          if (input.isEmpty || isLastCharOperator) {
            input += '0.';
          } else {
            input += text;
          }
        } else if (isNewCharOperator) {
          if (input.isEmpty) {
            // Allow starting with '-' for negative numbers, but not other operators
            if (text == '-') {
              input += text;
            }
            return; // Prevent starting with '+', '×', '÷'
          }
          if (isLastCharOperator) {
            // If the last character is an operator and the new character is also an operator, replace the last one.
            // This allows changing the last operation (e.g., "5+-" becomes "5-")
            input = input.substring(0, input.length - 1) + text;
          } else {
            // Append the new operator
            input += text;
          }
        } else {
          // This is a digit (0-9)
          input += text;
        }
      }
    });
  }

  Widget _buildButton(String text, {Color? color}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () => buttonPressed(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[850],
            padding: const EdgeInsets.all(22),
            shape: const CircleBorder(),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<List<String>> buttonRows = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['C', '0', '.', '+'], // Added '.' button
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CalcMate'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      input.isEmpty ? '0' : input, // Show '0' when input is empty
                      style: TextStyle(fontSize: 30, color: Colors.grey[400]),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      result.isEmpty ? '0' : result, // Show '0' when result is empty
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                ...buttonRows.map<Widget>((row) {
                  return Row(
                    children: row.map<Widget>((text) {
                      Color? color = ['+', '-', '×', '÷'].contains(text)
                          ? Colors.teal
                          : text == 'C'
                              ? Colors.redAccent
                              : text == '='
                                  ? Colors.teal
                                  : null;
                      return _buildButton(text, color: color);
                    }).toList(),
                  );
                }).toList(),
                Row(
                  children: <Widget>[
                    _buildButton('=', color: Colors.teal), // Place '=' separately for larger button or specific placement
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
