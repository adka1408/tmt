#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartSetup
        rlRun "output=\$(mktemp)" 0 "Create output file"
        rlRun "set -o pipefail"
    rlPhaseEnd

    rlPhaseStartTest "tmt plan ls"
        rlRun "tmt plan ls | tee $output"
        rlAssertGrep "/plans/features/core" $output
        rlAssertGrep "/plans/features/basic" $output
    rlPhaseEnd

    rlPhaseStartTest "tmt plan ls <name>"
        rlRun "tmt plan ls core | tee $output"
        rlAssertGrep "/plans/features/core" $output
        rlAssertNotGrep "/plans/features/basic" $output
    rlPhaseEnd

    rlPhaseStartTest "tmt plan ls non-existent"
        rlRun "tmt plan ls non-existent | tee $output"
        rlRun "[[ $(wc -l <$output) == 0 ]]" 0 "Check no output"
    rlPhaseEnd

    for filter in '-f' '--filter'; do
        rlPhaseStartTest "tmt plan show $filter <filter>"
            rlRun "tmt plan show $filter description:.*fast.* | tee $output"
            rlAssertGrep '/plans/features/core' $output
            rlAssertNotGrep '/plans/features/basic' $output
        rlPhaseEnd
    done

    for name in '-n' '--name'; do
        rlPhaseStartTest "tmt run plan $name <name>"
            tmt='tmt run -r discover'
            rlRun "$tmt plan $name core | tee $output"
            rlAssertGrep "^/plans/features/core" $output
            rlAssertNotGrep "^/plans/features/basic" $output
            rlRun "$tmt plan $name non-existent 2>&1 | tee $output" 2
            rlAssertGrep "No plans found." $output
        rlPhaseEnd
    done

    rlPhaseStartCleanup
        rlRun "rm $output" 0 "Remove output file"
    rlPhaseEnd
rlJournalEnd
