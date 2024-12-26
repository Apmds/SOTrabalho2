#!/bin/bash

# É necessário ter o executado o comando "make all" previamente
# Argumento opcional com o número de vezes que se pretendem executar os testes

TOTAL_TESTS=0
SUCCESS_TESTS=0
FAILURE_TESTS=0

function clean {
    for file in "$@"; do
        rm "$file"
    done
}


function result {
    ((TOTAL_TESTS++))
    [[ "$1" -eq 0 ]] && { echo "Test result: SUCCESS"; ((SUCCESS_TESTS++)); }
    [[ "$1" -eq 1 ]] && { echo "Test result: FAILURE"; ((FAILURE_TESTS++)); }
}



# Avaliamos se o referre passa para S apenas quando todos os elementos das equipas estão a s ou S
function testRefereeStartingGame {
    echo
    echo "=== Testing Referee Starting Game ==="
    echo

    previousLine=""
    currentLine=""
    ./probSemSharedMemSoccerGame > "resultFile.txt"
    while read -r line; do
        currentLine="$line"

        # Verificar se o último caracter da linha é R
        if [[ "${currentLine: -1}" == "S" ]]; then

            # Verificar se a linha anterior tem 5 p's e 5 P's
            num_s=$(echo "$previousLine" | grep -o "s" | wc -l)
            num_S=$(echo "$previousLine" | grep -o "S" | wc -l)

            if [[ "$num_s" -eq 5 && "$num_S" -eq 5 ]]; then
                echo "OK: Referee is starting the game with:"
                echo "$num_s players/golies of team 1 waiting start"
                echo "$num_S players/golies of team 2 waiting start"
                result 0
            else
                echo "ERROR: Referee is starting the game with:"
                echo "$num_s players/golies of team 1 waiting start"
                echo "$num_S players/golies of team 2 waiting start"
                result 1
            fi
            break
        fi

        previousLine="$currentLine"
    done < "resultFile.txt"

    clean "resultFile.txt"
    echo
}

# Avaliamos se o referee passa a R apenas quando todos os elementos das equipas estão a p ou P
function testRefereeing {
    echo
    echo "=== Testing Refereeing ==="
    echo

    previousLine=""
    currentLine=""
    ./probSemSharedMemSoccerGame > "resultFile.txt"
    while read -r line; do
        currentLine="$line"

        # Verificar se o último caracter da linha é R
        if [[ "${currentLine: -1}" == "R" ]]; then

            # Verificar se a linha anterior tem 5 p's e 5 P's
            num_p=$(echo "$previousLine" | grep -o "p" | wc -l)
            num_P=$(echo "$previousLine" | grep -o "P" | wc -l)

            if [[ "$num_p" -eq 5 && "$num_P" -eq 5 ]]; then
                echo "OK: Referee starts refereeing with:"
                echo "$num_p players/golies of team 1 playing"
                echo "$num_P players/golies of team 2 playing"
                result 0
            else
                echo "ERROR: Referee starts refereeing with:"
                echo "$num_p players/golies of team 1 playing"
                echo "$num_P players/golies of team 2 playing"
                result 1
            fi
            break
        fi

        previousLine="$currentLine"
    done < "resultFile.txt"

    clean "resultFile.txt"
    echo
}


# Verificamos o número de elementos a p, P, L e E
function checkFinalResult {
    echo
    echo "=== Testing Final Result ==="
    echo

    ./probSemSharedMemSoccerGame > "resultFile.txt"
    if [[ ! -s "resultFile.txt" ]]; then
        echo "Error: resultFile.txt is empty or not generated correctly"
        ((failure++))
        continue
    fi
    lastLine=$(tail -n 1 resultFile.txt)
    num_p=$(echo "$lastLine" | grep -o "p" | wc -l) # team 1    
    num_P=$(echo "$lastLine" | grep -o "P" | wc -l) # team 2
    num_E=$(echo "$lastLine" | grep -o "E" | wc -l) # ending game   
    num_L=$(echo "$lastLine" | grep -o "L" | wc -l) # late
    echo "$num_p players/goalies on team 1"
    echo "$num_P players/goalies on team 2"
    echo "$num_L late players/goalies"
    if [[ "$num_E" -eq 1 ]]; then
        echo "Referee ended the game"
    fi
    if [[ "$num_p" -eq 5 && "$num_P" -eq 5 && "$num_E" -eq 1 && "$num_L" -eq 3 ]]; then
        result 0
    else
        result 1
    fi

    clean "resultFile.txt"
    echo
}


function summaryOfTests() {
    echo
    echo "---- SUMMARY OF TESTS PERFORMED ----"
    echo
    echo "NUMBER OF TESTS PERFORMED: $TOTAL_TESTS"
    echo "NUMBER OF SUCCESSFUL TESTS: $SUCCESS_TESTS"
    echo "NUMBER OF FAILED TESTS: $FAILURE_TESTS"
    echo
}

function main {

    testRefereeStartingGame
    testRefereeing # TESTAR O INÍCIO DA ARBITRAGEM
    checkFinalResult # TESTAR O FINAL DO JOGO

    summaryOfTests
}


main