#!/bin/bash

# É necessário ter o executado o comando "make all" previamente
# Argumento com o número de vezes que se pretendem executar os testes
# Em caso de erro, o ficheiro resultsFile.txt não é apagado

PEOPLE_IN_TEAM=5 # Inclui players e goalies
TOTAL_PEOPLE=13 # Excluíndo o referee

function parseArgs {
    if [[ $# -ne 1 ]]; then
        echo "USAGE: ./soccergameTest.sh <number of runs>"
        exit 1
    fi
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        numRuns="$1"
    else
        echo "ERROR: Invalid number of runs."
        exit 1
    fi
}

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


# Avalia se o referee passa para S apenas quando todos os elementos das equipas estão a s ou S
function testRefereeStartingGame {
    echo
    echo "=== Testing Referee Starting Game ==="
    echo

    previousLine=""
    currentLine=""
    while read -r line; do
        currentLine="$line"

        # Verificar se o último caracter da linha é R
        if [[ "${currentLine: -1}" == "S" ]]; then

            # Verificar se a linha anterior tem 5 p's e 5 P's
            num_s=$(echo "$previousLine" | grep -o "s" | wc -l)
            num_S=$(echo "$previousLine" | grep -o "S" | wc -l)

            if [[ "$num_s" -eq "$PEOPLE_IN_TEAM" && "$num_S" -eq "$PEOPLE_IN_TEAM" ]]; then
                echo "OK: Referee is starting the game with:"
                echo "$num_s players/golies of team 1 waiting start."
                echo "$num_S players/golies of team 2 waiting start."
                result 0
            else
                echo "ERROR: Referee is starting the game with:"
                echo "$num_s players/golies of team 1 waiting start."
                echo "$num_S players/golies of team 2 waiting start."
                result 1
            fi
            break
        fi

        previousLine="$currentLine"
    done < "$FILE"

    echo
}

# Avalia se o referee passa a R apenas quando todos os elementos das equipas estão a p ou P
# Verifica se R aparece apenas uma vez
function testRefereeing {
    echo
    echo "=== Testing Refereeing ==="
    echo

    previousLine=""
    currentLine=""
    count_R=0
    check=1
    while read -r line; do
        currentLine="$line"

        # Verificar se o último caracter da linha é R
        if [[ "${currentLine: -1}" == "R" ]]; then
            ((count_R++))

            # Verificar se a linha anterior tem 5 p's e 5 P's
            num_p=$(echo "$previousLine" | grep -o "p" | wc -l)
            num_P=$(echo "$previousLine" | grep -o "P" | wc -l)

            if [[ "$num_p" -eq "$PEOPLE_IN_TEAM" && "$num_P" -eq "$PEOPLE_IN_TEAM" ]]; then
                echo "OK: Referee starts refereeing with:"
                echo "$num_p players/golies of team 1 playing."
                echo "$num_P players/golies of team 2 playing."
                check=0
            else
                echo "ERROR: Referee starts refereeing with:"
                echo "$num_p players/golies of team 1 playing."
                echo "$num_P players/golies of team 2 playing."
                check=1
            fi
            break
        fi

        previousLine="$currentLine"
    done < "$FILE"

    if [[ "$count_R" -eq 1 ]]; then
        echo "OK: R appears only once."
    else
        echo "ERROR: R appears more than once."
    fi

    if [[ "$count_R" -eq 1 && "$check" -eq 0 ]]; then
        result 0
    else
        result 1
    fi
    echo
}


# Verifica a passagem para o estado F dos players/goalies
function testFormingTeam {
    echo
    echo "=== Testing Transition to State F ==="
    echo

    previousLine=""
    currentLine=""
    lineNumber=0
    success=0
    failure=0
    numTransitions=0

    while read -r line; do
        ((lineNumber++))

        if [[ "$lineNumber" -eq 1 ]]; then
            previousLine="$line"
            continue
        fi

        # Verificar cada posição na linha atual comparando com a anterior
        for ((i = 0; i < ${#line}; i++)); do
            currentChar="${line:$i:1}"
            previousChar="${previousLine:$i:1}"

            if [[ "$currentChar" == "F" && "$previousChar" == "A" ]]; then
                echo "> Transition to F detected at line $lineNumber."
                ((numTransitions++))
                # Validar condições para formar a equipa
                num_W=$(echo "$line" | grep -o "W" | wc -l)
                if [[ "$num_W" -ge "$((PEOPLE_IN_TEAM-1))" ]]; then
                    echo "OK: Enough players in W to form a team."
                    ((success++))
                else
                    echo "ERROR: Not enough players in W to form a team."
                    ((failure++))
                fi
            fi
        done

        previousLine="$line"
    done < "$FILE"
    echo "Total transitions to F: $numTransitions."
    if [[ "$failure" -eq 0 && "$numTransitions" -eq 2 ]]; then
        result 0
    else
        result 1
    fi
}


# Verifica o número de elementos a p, P, L e E
function checkFinalResult {
    echo
    echo "=== Testing Final Result ==="
    echo

    
    if [[ ! -s "$FILE" ]]; then
        echo "Error: resultFile.txt is empty or not generated correctly."
        ((failure++))
        continue
    fi
    lastLine=$(tail -n 1 "$FILE")
    num_p=$(echo "$lastLine" | grep -o "p" | wc -l) # team 1    
    num_P=$(echo "$lastLine" | grep -o "P" | wc -l) # team 2
    num_E=$(echo "$lastLine" | grep -o "E" | wc -l) # ending game   
    num_L=$(echo "$lastLine" | grep -o "L" | wc -l) # late
    echo "$num_p players/goalies on team 1."
    echo "$num_P players/goalies on team 2."
    echo "$num_L late players/goalies."
    if [[ "$num_E" -eq 1 ]]; then
        echo "Referee ended the game."
    fi
    if [[ "$num_p" -eq "$PEOPLE_IN_TEAM" && "$num_P" -eq "$PEOPLE_IN_TEAM" && "$num_E" -eq 1 && "$num_L" -eq "$((TOTAL_PEOPLE-2*PEOPLE_IN_TEAM))" ]]; then
        result 0
    else
        result 1
    fi

    echo
}


function summaryOfTests() {
    echo
    echo "---- Summary of test performed ----"
    echo
    echo "Number of tests performed: $TOTAL_TESTS"
    echo "Number of successful tests: $SUCCESS_TESTS"
    echo "Number of failed tests: $FAILURE_TESTS"
    echo
}

function main {

    parseArgs "$@"
    overallPass=0
    overallFail=0

    for ((run = 1; run <= numRuns; run++)); do
        echo
        echo " >> RUN $run"
        TOTAL_TESTS=0
        SUCCESS_TESTS=0
        FAILURE_TESTS=0
        FILE="resultsFile.txt"

        ./probSemSharedMemSoccerGame > "$FILE"

        testRefereeStartingGame # TESTAR A PASSAGEM PARA O ESTADO S DO REFEREE
        testRefereeing # TESTAR O INÍCIO DA ARBITRAGEM
        testFormingTeam # TESTAR A TRANSIÇÃO PARA O ESTADO F DE PLAYERS/GOALIES
        checkFinalResult # TESTAR O FINAL DO JOGO

        summaryOfTests

        overallPass=$((overallPass + $SUCCESS_TESTS))
        overallFail=$((overallFail + $FAILURE_TESTS))

        if [[ "$FAILURE_TESTS" -gt 0 ]]; then
            echo "AN ERROR OCCURRED"
            break
        fi
    done
    [[ "$FAILURE_TESTS" -eq 0 ]] && { clean "$FILE"; }

    echo
    echo "=== OVERALL SUMMARY ==="
    echo "TOTAL RUNS: $numRuns"
    echo "TOTAL TESTS PASSED: $overallPass"
    echo "TOTAL TESTS FAILED: $overallFail"

}


main "$@"