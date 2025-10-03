Set-StrictMode -Version Latest

# Cross-platform key reader using a background .NET thread and a concurrent queue.
# Avoids reliance on [Console]::KeyAvailable which can be unreliable across hosts.

Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Collections.Concurrent;
using System.Threading;

public class PmcKeyReader
{
    private readonly ConcurrentQueue<ConsoleKeyInfo> _queue = new ConcurrentQueue<ConsoleKeyInfo>();
    private Thread _readerThread;
    private volatile bool _running = false;

    public void Start()
    {
        if (_running) return;
        _running = true;
        _readerThread = new Thread(() =>
        {
            while (_running)
            {
                try
                {
                    // Blocking read; returns when a key is pressed
                    var key = Console.ReadKey(true);
                    _queue.Enqueue(key);
                }
                catch
                {
                    // If the host doesn't support ReadKey at this moment, back off briefly
                    Thread.Sleep(25);
                }
            }
        });
        _readerThread.IsBackground = true;
        _readerThread.Name = "PmcKeyReader";
        _readerThread.Start();
    }

    public void Stop()
    {
        _running = false;
        try { _readerThread?.Join(200); } catch { }
        _readerThread = null;
        while (_queue.TryDequeue(out _)) {}
    }

    public bool TryRead(out ConsoleKeyInfo key)
    {
        return _queue.TryDequeue(out key);
    }
}
"@

function Get-PmcKeyReader {
    if (-not $Script:PmcKeyReader) {
        $Script:PmcKeyReader = [PmcKeyReader]::new()
        $Script:PmcKeyReader.Start()
    }
    return $Script:PmcKeyReader
}

function Stop-PmcKeyReader {
    if ($Script:PmcKeyReader) {
        $Script:PmcKeyReader.Stop()
        $Script:PmcKeyReader = $null
    }
}

Export-ModuleMember -Function Get-PmcKeyReader, Stop-PmcKeyReader

