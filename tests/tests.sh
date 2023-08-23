#!/bin/sh

passed_count=0
run_count=0

run_test()
{
    run_count=$((run_count+1))
    echo "Test $run_count"
    if [ $1 = $2 ]; then
        echo "test passed"
        passed_count=$((passed_count+1))
    else
        echo "test failed"
    fi
}
run_test `./seve -cs tests/add.cos` "100"
run_test `./seve -cs tests/dup.cos` "muck"
run_test `./seve -cs tests/duup.cos` "2"

echo "Passed ${passed_count}/${run_count}"