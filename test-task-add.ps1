#!/usr/bin/env pwsh

$taskText = "test"

$parsedText = $taskText.Trim()
$project = 'inbox'
$priority = 'medium'
$due = $null

Write-Host "Input: '$taskText'" -ForegroundColor Cyan

# Extract @project
if ($parsedText -match '@(\S+)') {
    $project = $matches[1]
    $parsedText = $parsedText -replace '@\S+\s*', ''
    Write-Host "Found project: $project" -ForegroundColor Yellow
}
Write-Host "After project extraction: '$parsedText'" -ForegroundColor Gray

# Extract #priority (high/medium/low/h/m/l)
if ($parsedText -match '#(high|medium|low|h|m|l)') {
    $priMatch = $matches[1]
    $priority = switch ($priMatch) {
        'h' { 'high' }
        'm' { 'medium' }
        'l' { 'low' }
        default { $priMatch }
    }
    $parsedText = $parsedText -replace '#(high|medium|low|h|m|l)\s*', ''
    Write-Host "Found priority: $priority" -ForegroundColor Yellow
}
Write-Host "After priority extraction: '$parsedText'" -ForegroundColor Gray

# Extract !due (today/tomorrow/+N for days)
if ($parsedText -match '!(today|tomorrow|\+\d+)') {
    $dueMatch = $matches[1]
    $due = switch -Regex ($dueMatch) {
        'today' { (Get-Date).ToString('yyyy-MM-dd') }
        'tomorrow' { (Get-Date).AddDays(1).ToString('yyyy-MM-dd') }
        '^\+(\d+)$' { (Get-Date).AddDays([int]$matches[1]).ToString('yyyy-MM-dd') }
    }
    $parsedText = $parsedText -replace '!(today|tomorrow|\+\d+)\s*', ''
    Write-Host "Found due: $due" -ForegroundColor Yellow
}
Write-Host "After due extraction: '$parsedText'" -ForegroundColor Gray

Write-Host "`nFinal task text: '$($parsedText.Trim())'" -ForegroundColor Green
Write-Host "Project: $project" -ForegroundColor Green
Write-Host "Priority: $priority" -ForegroundColor Green
Write-Host "Due: $due" -ForegroundColor Green
