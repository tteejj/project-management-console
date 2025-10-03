# Testable Console wrapper that can inject input
class TestableConsole {
    hidden [System.Collections.Queue] $InputQueue = [System.Collections.Queue]::new()
    hidden [System.Text.StringBuilder] $CapturedOutput = [System.Text.StringBuilder]::new()
    [bool] $CaptureOutput = $false

    [void] QueueInput([string]$text) {
        $this.InputQueue.Enqueue($text)
    }

    [void] QueueKey([System.ConsoleKey]$key) {
        $keyInfo = [System.ConsoleKeyInfo]::new([char]0, $key, $false, $false, $false)
        $this.InputQueue.Enqueue($keyInfo)
    }

    [void] QueueKeyChar([char]$char) {
        $keyInfo = [System.ConsoleKeyInfo]::new($char, [System.ConsoleKey]::A, $false, $false, $false)
        $this.InputQueue.Enqueue($keyInfo)
    }

    [string] ReadLine() {
        if ($this.InputQueue.Count -gt 0) {
            $input = $this.InputQueue.Dequeue()
            if ($this.CaptureOutput) {
                $this.CapturedOutput.AppendLine("INPUT: $input")
            }
            return $input
        }
        throw "No input queued for ReadLine"
    }

    [System.ConsoleKeyInfo] ReadKey([bool]$intercept) {
        if ($this.InputQueue.Count -gt 0) {
            $input = $this.InputQueue.Dequeue()
            if ($input -is [System.ConsoleKeyInfo]) {
                if ($this.CaptureOutput) {
                    $this.CapturedOutput.AppendLine("KEY: $($input.Key)")
                }
                return $input
            } else {
                # Convert string to keyinfo
                $char = $input[0]
                $keyInfo = [System.ConsoleKeyInfo]::new($char, [System.ConsoleKey]::A, $false, $false, $false)
                if ($this.CaptureOutput) {
                    $this.CapturedOutput.AppendLine("KEY: $char")
                }
                return $keyInfo
            }
        }
        throw "No input queued for ReadKey"
    }

    [void] SetCursorPosition([int]$left, [int]$top) {
        # Mock - do nothing
    }

    [string] GetCapturedOutput() {
        return $this.CapturedOutput.ToString()
    }

    [void] ClearCapture() {
        $this.CapturedOutput.Clear()
    }
}
