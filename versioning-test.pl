#!/usr/bin/perl -w

use POSIX qw(strftime);
use File::Basename;

# Function to find token file using config-helper.sh
# Maintains backward compatibility with dev-localhost/
sub find_token {
    my $project = shift;

    # Use bash to source config-helper.sh and call find_token_file
    my $token = `bash -c 'source scripts/config-helper.sh 2>/dev/null && find_token_file "$project" 2>/dev/null'`;
    chomp($token);

    # Fallback to dev-localhost if dynamic discovery fails
    if (!$token || !-f $token) {
        my @legacy_tokens = glob("dev-localhost/err0-$project-*.json");
        if (@legacy_tokens) {
            $token = $legacy_tokens[0];
        } else {
            die "ERROR: No token found for project '$project'. " .
                "Expected in tokens/ or dev-localhost/ directory.\n";
        }
    }

    return $token;
}

system('rm -rf ./tmp') == 0 || die '[VERSIONING-1] unable to remove tmp';
system('mkdir ./tmp') == 0 || die '[VERSIONING-2] unable to mkdir tmp';
system('cd ./tmp && git init .') == 0 || die '[VERSIONING-3] unable to git init';

# initial A.java
{
    open my $fh, '>', 'tmp/A.java';

    print {$fh} <<EOF;
public class A {

    private static final Logger logger = LogManager.getLogger(A.class);

    /**
     * Method comment
     */
    void method1() {

        logger.trace("Starting...");

        var foo = false;
        if (foo) {
            logger.debug("foo is true.");

            logger.info("info level");
            logger.warn("warn level");
            logger.error("error level");

            // this is always fatal
            logger.fatal("fatal level");

            throw new RuntimeException("This is an exception");
        }

        String placeholder = "__PLACEHOLDER__";

        logger.trace("Finishing...");
    }
}
EOF

    close $fh;
}

# Find and copy token file
my $token_file = find_token('example-project');
my $token_basename = basename($token_file);
system("cp '$token_file' tmp/") == 0 || die '[VERSIONING-6] unable to copy token';
system('cd ./tmp && git add . && git commit -m .') == 0 || die '[VERSIONING-4] unable to add A.java to git';

system("cd ./tmp && ../err0agent-dev-insert.sh '$token_basename' .") == 0 || die '[VERSIONING-5] unable to insert error codes';

system('cd ./tmp && git add . && git commit -m . && git tag v1.0.0') == 0 || die '[VERSIONING-7] unable to add changes';

system("cd ./tmp && ../err0agent-dev-check.sh '$token_basename' .") == 0 || die '[VERSIONING-8] unable to check error codes';

{
    open my $fh, '>', 'tmp/A.java';

    print {$fh} <<EOF;
public class A {

    private static final Logger logger = LogManager.getLogger(A.class);

    /**
     * Method comment
     */
    void method1() {

        logger.trace("Starting...");

        var foo = false;
        if (foo) {
            logger.debug("foo is true.");

            // removed logger.info to remove an error code.
            logger.warn("[EG-2] warn level");
            logger.error("[EG-3] ALERT THE MESSAGE CHANGED");

            // this is always fatal
            logger.fatal("[EG-4] fatal level");

            // all errors below have their line number changed
            throw new RuntimeException("[EG-5] This is an exception");
        }

        String placeholder = "EG-6";

        logger.fatal("Added fatal condition");

        throw new RuntimeException("Added exception");

        logger.trace("Finishing...");
    }
}
EOF

    close $fh;
}

system('cd ./tmp && git add . && git commit -m .') == 0 || die '[VERSIONING-9] unable to add A.java to git';

system("cd ./tmp && ../err0agent-dev-insert.sh '$token_basename' .") == 0 || die '[VERSIONING-10] unable to insert error codes';

system('cd ./tmp && git add . && git commit -m . && git tag v1.0.1') == 0 || die '[VERSIONING-11] unable to add changes';

system("cd ./tmp && ../err0agent-dev-check.sh '$token_basename' .") == 0 || die '[VERSIONING-12] unable to check error codes';

system('cd ./tmp && git branch support/v1.0.1 && git checkout -f support/v1.0.1') == 0 || die '[VERSIONING-13] unable to switch to support branch';

{
    open my $fh, '>', 'tmp/A.java';

    print {$fh} <<EOF;
public class A {

    private static final Logger logger = LogManager.getLogger(A.class);

    /**
     * Method comment
     */
    void method1() {

        logger.trace("Starting...");

        var foo = false;
        if (foo) {
            logger.debug("foo is true.");

            logger.info("[EG-1] info level restored from backup");
            logger.info("additional info level not restored");
            // removed logger.info to remove an error code.
            logger.warn("[EG-2] warn level");
            logger.error("[EG-3] ALERT THE MESSAGE CHANGED");

            // this is always fatal
            logger.fatal("[EG-4] fatal level");

            // all errors below have their line number changed
            throw new RuntimeException("[EG-5] This is an exception");
        }

        String placeholder = "EG-6";

        logger.fatal("[EG-7] Added fatal condition");

        throw new RuntimeException("[EG-8] Added exception");

        logger.trace("Finishing...");
    }
}
EOF

    close $fh;
}

system('cd ./tmp && git add . && git commit -m .') == 0 || die '[VERSIONING-14] unable to add A.java to git';

system("cd ./tmp && ../err0agent-dev-insert.sh '$token_basename' .") == 0 || die '[VERSIONING-15] unable to insert error codes';

system('cd ./tmp && git add . && git commit -m .') == 0 || die '[VERSIONING-16] unable to git commit';

system('cd ./tmp && git tag v1.0.1-patch-1') == 0 || die '[VERSIONING-17] unable to tag support release';

system("cd ./tmp && ../err0agent-dev-check.sh '$token_basename' .") == 0 || die '[VERSIONING-18] unable to check error codes';

system('cd ./tmp && git checkout -f master') == 0 || die '[VERSIONING-19] unable to switch to master branch';

{
    open my $fh, '>', 'tmp/A.java';

    print {$fh} <<EOF;
public class A {

    private static final Logger logger = LogManager.getLogger(A.class);

    /**
     * Method comment
     */
    void method1() {

        logger.trace("Starting...");

        var foo = false;
        if (foo) {
            logger.debug("foo is true.");

            // removed logger.info to remove an error code.
            logger.warn("[EG-2] warn level");
            logger.error("[EG-3] ALERT THE MESSAGE CHANGED");

            // this is always fatal
            logger.fatal("[EG-4] fatal level");

            // all errors below have their line number changed
            throw new RuntimeException("[EG-5] This is an exception");
        }

        String placeholder = "EG-6";

        logger.fatal("[EG-7] Added fatal condition");

        throw new RuntimeException("[EG-8] Added exception");

        // unrelated change here, this is for version 1.0.2

        logger.trace("Finishing...");
    }
}
EOF

    close $fh;
}

system('cd ./tmp && git add . && git commit -m .') == 0 || die '[VERSIONING-20] unable to add A.java to git';

system("cd ./tmp && ../err0agent-dev-insert.sh '$token_basename' .") == 0 || die '[VERSIONING-21] unable to insert error codes';

system('cd ./tmp && git add . && git commit -m .') == 0 && die '[VERSIONING-22] should not have changes to add';

system('cd ./tmp && git tag v1.0.2') == 0 || die '[VERSIONING-23] unable to tag next master release';

system("cd ./tmp && ../err0agent-dev-check.sh '$token_basename' .") == 0 || die '[VERSIONING-24] unable to check error codes';

system('cd ./tmp && git checkout -f support/v1.0.1') == 0 || die '[VERSIONING-25] unable to switch to support branch';

{
    open my $fh, '>', 'tmp/A.java';

    print {$fh} <<EOF;
public class A {

    private static final Logger logger = LogManager.getLogger(A.class);

    /**
     * Method comment
     */
    void method1() {

        logger.trace("Starting...");

        // another unrelated change this is for patch-2

        var foo = false;
        if (foo) {
            logger.debug("foo is true.");

            // we didn't need it for long // again removed // logger.info("[EG-1] info level restored from backup");
            logger.info("[EG-9] additional info level not restored");
            // removed logger.info to remove an error code.
            logger.warn("[EG-2] warn level");
            logger.error("[EG-3] ALERT THE MESSAGE CHANGED");

            // this is always fatal
            logger.fatal("[EG-4] fatal level");

            // all errors below have their line number changed
            throw new RuntimeException("[EG-5] This is an exception");
        }

        String placeholder = "EG-6";

        logger.fatal("[EG-7] Added fatal condition");

        throw new RuntimeException("[EG-8] Added exception");

        logger.trace("Finishing...");
    }
}
EOF

    close $fh;
}

system('cd ./tmp && git add . && git commit -m .') == 0 || die '[VERSIONING-26] unable to add A.java to git';

system("cd ./tmp && ../err0agent-dev-insert.sh '$token_basename' .") == 0 || die '[VERSIONING-27] unable to insert error codes';

system('cd ./tmp && git add . && git commit -m .') == 0 && die '[VERSIONING-28] should not have changes to add';

system('cd ./tmp && git tag v1.0.1-patch-2') == 0 || die '[VERSIONING-29] unable to tag support release';

system("cd ./tmp && ../err0agent-dev-check.sh '$token_basename' .") == 0 || die '[VERSIONING-30] unable to check error codes';

{
    open my $fh, '>', 'tmp/A.java';

    print {$fh} <<EOF;
public class A {

    private static final Logger logger = LogManager.getLogger(A.class);

    /**
     * Method comment
     */
    void method1() {

        logger.trace("Starting...");

        // another unrelated change this is for patch-2

        var foo = false;
        if (foo) {
            logger.debug("foo is true.");

            // we didn't need it for long // again removed // logger.info("[EG-1] info level restored from backup");
            logger.info("[EG-9] additional info level not restored");
            // removed logger.info to remove an error code.
            logger.warn("[EG-2] warn level");
            logger.error("[EG-3] ALERT THE MESSAGE CHANGED");

            var bar = true;
            if (bar) {
                throw new RuntimeException("Not covered by Err0.io!");
            }

            // this is always fatal
            logger.fatal("[EG-4] fatal level");

            // all errors below have their line number changed
            throw new RuntimeException("[EG-5] This is an exception");
        }

        String placeholder = "EG-6";

        logger.fatal("[EG-7] Added fatal condition");

        throw new RuntimeException("[EG-8] Added exception");

        logger.trace("Finishing...");
    }
}
EOF

    close $fh;
}

system('cd ./tmp && git add . && git commit -m .') == 0 || die '[VERSIONING-31] unable to add A.java to git';

system('cd ./tmp && git tag v1.0.1-patch-3') == 0 || die '[VERSIONING-32] unable to tag support release';

# don't insert codes

system("cd ./tmp && ../err0agent-dev-check.sh '$token_basename' .") != 0 || die '[VERSIONING-33] check error codes should indicate failure';

print "VERSIONING test: success.\n";

exit 0;