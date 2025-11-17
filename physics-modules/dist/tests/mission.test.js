"use strict";
/**
 * Mission System Tests
 *
 * Comprehensive testing of landing zones, scoring, objectives, and checklists
 */
Object.defineProperty(exports, "__esModule", { value: true });
const mission_1 = require("../src/mission");
class MissionTests {
    constructor() {
        this.passed = 0;
        this.failed = 0;
        this.tests = [];
    }
    assert(condition, message) {
        if (condition) {
            this.passed++;
            this.tests.push(`✓ ${message}: PASS`);
        }
        else {
            this.failed++;
            this.tests.push(`✗ ${message}: FAIL`);
        }
    }
    assertNear(actual, expected, tolerance, message) {
        const diff = Math.abs(actual - expected);
        if (diff <= tolerance) {
            this.passed++;
            this.tests.push(`✓ ${message}: PASS`);
        }
        else {
            this.failed++;
            this.tests.push(`✗ ${message}: FAIL: ${actual} vs ${expected} (diff: ${diff})`);
        }
    }
    printResults() {
        console.log('\n=== TEST RESULTS ===\n');
        this.tests.forEach(test => console.log(test));
        console.log(`\n${this.passed} passed, ${this.failed} failed (${this.passed + this.failed} total)\n`);
        if (this.failed === 0) {
            console.log('🎉 All tests passed!\n');
        }
        else {
            console.log(`❌ ${this.failed} test(s) failed\n`);
        }
    }
    // Test 1: Landing Zone Database - Get Zone
    testLandingZoneGet() {
        console.log('\nTest 1: Landing Zone Database - Get Zone');
        const db = new mission_1.LandingZoneDatabase();
        const zone = db.getZone('lz_tranquility');
        console.log(`  Zone: ${zone?.name}`);
        console.log(`  Difficulty: ${zone?.difficulty}`);
        this.assert(zone !== undefined, 'Zone found');
        this.assert(zone?.id === 'lz_tranquility', 'Correct zone ID');
        this.assert(zone?.difficulty === 'easy', 'Correct difficulty');
    }
    // Test 2: Landing Zone Database - Get All Zones
    testLandingZoneGetAll() {
        console.log('\nTest 2: Landing Zone Database - Get All Zones');
        const db = new mission_1.LandingZoneDatabase();
        const zones = db.getAllZones();
        console.log(`  Total zones: ${zones.length}`);
        this.assert(zones.length >= 4, 'At least 4 zones');
        this.assert(zones.every(z => z.id && z.name), 'All zones have ID and name');
    }
    // Test 3: Landing Zone Database - Filter by Difficulty
    testLandingZoneFilterByDifficulty() {
        console.log('\nTest 3: Landing Zone Database - Filter by Difficulty');
        const db = new mission_1.LandingZoneDatabase();
        const easyZones = db.getZonesByDifficulty('easy');
        const hardZones = db.getZonesByDifficulty('hard');
        console.log(`  Easy zones: ${easyZones.length}`);
        console.log(`  Hard zones: ${hardZones.length}`);
        this.assert(easyZones.length > 0, 'Has easy zones');
        this.assert(hardZones.length > 0, 'Has hard zones');
        this.assert(easyZones.every(z => z.difficulty === 'easy'), 'Easy zones filtered correctly');
    }
    // Test 4: Scoring - Perfect Landing
    testScoringPerfectLanding() {
        console.log('\nTest 4: Scoring - Perfect Landing');
        const calc = new mission_1.ScoringCalculator();
        const db = new mission_1.LandingZoneDatabase();
        const zone = db.getZone('lz_tranquility');
        const score = calc.calculateScore(0.5, // landingSpeed - very soft
        0.5, // landingAngle - very straight
        10, // distanceFromTarget - very close
        150, // fuelRemaining
        200, // initialFuel
        60, // missionTime
        120, // parTime
        100, // systemHealth - perfect
        3, // checklistsCompleted
        3, // totalChecklists
        zone);
        console.log(`  Total score: ${score.totalScore.toFixed(0)}`);
        console.log(`  Grade: ${score.grade}`);
        this.assert(score.totalScore > 1000, 'Good score for very good landing');
        this.assert(score.grade === 'B' || score.grade === 'A' || score.grade === 'S', 'Good grade');
    }
    // Test 5: Scoring - Poor Landing
    testScoringPoorLanding() {
        console.log('\nTest 5: Scoring - Poor Landing');
        const calc = new mission_1.ScoringCalculator();
        const db = new mission_1.LandingZoneDatabase();
        const zone = db.getZone('lz_tranquility');
        const score = calc.calculateScore(2.9, // landingSpeed - near limit
        9.0, // landingAngle - tilted
        400, // distanceFromTarget - far
        20, // fuelRemaining - low
        200, // initialFuel
        250, // missionTime - slow
        120, // parTime
        60, // systemHealth - damaged
        0, // checklistsCompleted - none
        3, // totalChecklists
        zone);
        console.log(`  Total score: ${score.totalScore.toFixed(0)}`);
        console.log(`  Grade: ${score.grade}`);
        this.assert(score.totalScore < 1000, 'Low score for poor landing');
        this.assert(score.grade === 'D' || score.grade === 'F', 'Low grade');
    }
    // Test 6: Scoring - Difficulty Multiplier
    testScoringDifficultyMultiplier() {
        console.log('\nTest 6: Scoring - Difficulty Multiplier');
        const calc = new mission_1.ScoringCalculator();
        const db = new mission_1.LandingZoneDatabase();
        const easyZone = db.getZone('lz_tranquility');
        const extremeZone = db.getZone('lz_shackleton');
        const easyScore = calc.calculateScore(1.0, 1.0, 10, 150, 200, 60, 120, 100, 3, 3, easyZone);
        const extremeScore = calc.calculateScore(1.0, 1.0, 10, 150, 200, 60, 120, 100, 3, 3, extremeZone);
        console.log(`  Easy score: ${easyScore.totalScore.toFixed(0)}`);
        console.log(`  Extreme score: ${extremeScore.totalScore.toFixed(0)}`);
        console.log(`  Multiplier ratio: ${(extremeScore.totalScore / easyScore.totalScore).toFixed(2)}`);
        console.log(`  Difficulty multipliers: Easy=${easyScore.difficultyMultiplier}, Extreme=${extremeScore.difficultyMultiplier}`);
        this.assert(extremeScore.totalScore > easyScore.totalScore, 'Extreme scores higher than easy');
        this.assertNear(extremeScore.difficultyMultiplier, 3.0, 0.1, 'Extreme has 3x multiplier');
    }
    // Test 7: Scoring - Landing Speed Component
    testScoringLandingSpeed() {
        console.log('\nTest 7: Scoring - Landing Speed Component');
        const calc = new mission_1.ScoringCalculator();
        const db = new mission_1.LandingZoneDatabase();
        const zone = db.getZone('lz_tranquility');
        const softLanding = calc.calculateScore(0.5, 0, 10, 150, 200, 60, 120, 100, 3, 3, zone);
        const hardLanding = calc.calculateScore(2.5, 0, 10, 150, 200, 60, 120, 100, 3, 3, zone);
        console.log(`  Soft landing speed score: ${softLanding.landingSpeedScore.toFixed(0)}`);
        console.log(`  Hard landing speed score: ${hardLanding.landingSpeedScore.toFixed(0)}`);
        this.assert(softLanding.landingSpeedScore > hardLanding.landingSpeedScore, 'Softer landing scores higher');
        this.assert(hardLanding.landingSpeedScore > 0, 'Hard landing still gets some points');
    }
    // Test 8: Scoring - Precision Bonus
    testScoringPrecisionBonus() {
        console.log('\nTest 8: Scoring - Precision Bonus');
        const calc = new mission_1.ScoringCalculator();
        const bonus1 = calc.calculatePrecisionBonus(5, 50); // Very close
        const bonus2 = calc.calculatePrecisionBonus(25, 50); // Middle
        const bonus3 = calc.calculatePrecisionBonus(100, 50); // Outside bonus radius
        console.log(`  5m bonus: ${bonus1.toFixed(0)}`);
        console.log(`  25m bonus: ${bonus2.toFixed(0)}`);
        console.log(`  100m bonus: ${bonus3.toFixed(0)}`);
        this.assert(bonus1 > bonus2, 'Closer distance = higher bonus');
        this.assert(bonus2 > bonus3, 'Middle distance > outside');
        this.assert(bonus3 === 0, 'No bonus outside radius');
    }
    // Test 9: Mission Builder - Training Mission
    testMissionBuilderTraining() {
        console.log('\nTest 9: Mission Builder - Training Mission');
        const builder = new mission_1.MissionBuilder();
        const mission = builder.createTrainingMission();
        console.log(`  Mission: ${mission.name}`);
        console.log(`  Landing zone: ${mission.landingZone.name}`);
        console.log(`  Objectives: ${mission.objectives.length}`);
        this.assert(mission.id === 'mission_training', 'Correct mission ID');
        this.assert(mission.objectives.length >= 3, 'Has multiple objectives');
        this.assert(mission.landingZone.difficulty === 'easy', 'Easy difficulty for training');
    }
    // Test 10: Mission Builder - Precision Mission
    testMissionBuilderPrecision() {
        console.log('\nTest 10: Mission Builder - Precision Mission');
        const builder = new mission_1.MissionBuilder();
        const mission = builder.createPrecisionMission();
        console.log(`  Mission: ${mission.name}`);
        console.log(`  Par time: ${mission.parTime}s`);
        this.assert(mission.id === 'mission_precision', 'Correct mission ID');
        this.assert(mission.landingZone.difficulty === 'medium', 'Medium difficulty');
    }
    // Test 11: Mission Builder - Challenge Mission
    testMissionBuilderChallenge() {
        console.log('\nTest 11: Mission Builder - Challenge Mission');
        const builder = new mission_1.MissionBuilder();
        const mission = builder.createChallengeMission();
        console.log(`  Mission: ${mission.name}`);
        console.log(`  Landing zone: ${mission.landingZone.name}`);
        this.assert(mission.id === 'mission_challenge', 'Correct mission ID');
        this.assert(mission.landingZone.difficulty === 'hard', 'Hard difficulty');
    }
    // Test 12: Checklist System - Add and Retrieve
    testChecklistAddRetrieve() {
        console.log('\nTest 12: Checklist System - Add and Retrieve');
        const system = new mission_1.ChecklistSystem();
        const checklist = {
            id: 'test_checklist',
            name: 'Test Checklist',
            phase: 'pre-landing',
            items: [
                { id: 'item1', description: 'Test item', completed: false, automated: false, verification: () => true }
            ],
            allCompleted: false
        };
        system.addChecklist(checklist);
        const retrieved = system.getChecklist('test_checklist');
        console.log(`  Checklist added: ${retrieved?.name}`);
        this.assert(retrieved !== undefined, 'Checklist retrieved');
        this.assert(retrieved?.id === 'test_checklist', 'Correct ID');
    }
    // Test 13: Checklist System - Update Completion
    testChecklistUpdateCompletion() {
        console.log('\nTest 13: Checklist System - Update Completion');
        const system = new mission_1.ChecklistSystem();
        let itemCompleted = false;
        const checklist = {
            id: 'test_checklist',
            name: 'Test',
            phase: 'pre-landing',
            items: [
                { id: 'item1', description: 'Item 1', completed: false, automated: false, verification: () => itemCompleted }
            ],
            allCompleted: false
        };
        system.addChecklist(checklist);
        // Update when not complete
        system.updateChecklist('test_checklist');
        let updated = system.getChecklist('test_checklist');
        console.log(`  Before completion: ${updated?.items[0].completed}`);
        this.assert(updated?.items[0].completed === false, 'Not completed yet');
        // Complete the item
        itemCompleted = true;
        system.updateChecklist('test_checklist');
        updated = system.getChecklist('test_checklist');
        console.log(`  After completion: ${updated?.items[0].completed}`);
        this.assert(updated?.items[0].completed === true, 'Item completed');
        this.assert(updated?.allCompleted === true, 'All completed');
    }
    // Test 14: Checklist System - Completion Rate
    testChecklistCompletionRate() {
        console.log('\nTest 14: Checklist System - Completion Rate');
        const system = new mission_1.ChecklistSystem();
        system.addChecklist({
            id: 'c1',
            name: 'C1',
            phase: 'pre-landing',
            items: [],
            allCompleted: true
        });
        system.addChecklist({
            id: 'c2',
            name: 'C2',
            phase: 'pre-landing',
            items: [],
            allCompleted: false
        });
        const rate = system.getCompletionRate();
        console.log(`  Completion rate: ${(rate * 100).toFixed(0)}%`);
        this.assertNear(rate, 0.5, 0.01, 'Completion rate 50%');
    }
    // Test 15: Mission System - Load Mission
    testMissionSystemLoadMission() {
        console.log('\nTest 15: Mission System - Load Mission');
        const system = new mission_1.MissionSystem();
        const mission = system.createTrainingMission();
        system.loadMission(mission);
        const loaded = system.getCurrentMission();
        console.log(`  Loaded mission: ${loaded?.name}`);
        this.assert(loaded !== null, 'Mission loaded');
        this.assert(loaded?.id === mission.id, 'Correct mission');
    }
    // Test 16: Mission System - Complete Objectives
    testMissionSystemCompleteObjectives() {
        console.log('\nTest 16: Mission System - Complete Objectives');
        const system = new mission_1.MissionSystem();
        const mission = system.createTrainingMission();
        system.loadMission(mission);
        system.completeObjective('obj_land_safely');
        const completion = system.getObjectivesCompletion();
        console.log(`  Objectives: ${completion.completed}/${completion.total}`);
        this.assert(completion.completed === 1, 'One objective completed');
        this.assert(completion.total >= 3, 'Multiple objectives total');
    }
    // Test 17: Mission System - Check Objective Condition
    testMissionSystemCheckObjective() {
        console.log('\nTest 17: Mission System - Check Objective Condition');
        const system = new mission_1.MissionSystem();
        const mission = system.createTrainingMission();
        system.loadMission(mission);
        // Check with false condition
        system.checkObjective('obj_land_safely', false);
        let completion = system.getObjectivesCompletion();
        this.assert(completion.completed === 0, 'Not completed with false condition');
        // Check with true condition
        system.checkObjective('obj_land_safely', true);
        completion = system.getObjectivesCompletion();
        this.assert(completion.completed === 1, 'Completed with true condition');
    }
    // Test 18: Mission System - Calculate Score
    testMissionSystemCalculateScore() {
        console.log('\nTest 18: Mission System - Calculate Score');
        const system = new mission_1.MissionSystem();
        const mission = system.createTrainingMission();
        system.loadMission(mission);
        system.startMission(0);
        const landingPos = { x: 0, y: 0, z: 1737400 };
        const targetPos = { x: 0, y: 0, z: 1737400 };
        const result = system.calculateMissionScore(1.5, // landingSpeed
        2.0, // landingAngle
        landingPos, targetPos, 100, // fuelRemaining
        95, // systemHealth
        60 // currentTime
        );
        console.log(`  Score: ${result.score.totalScore.toFixed(0)}`);
        console.log(`  Grade: ${result.score.grade}`);
        console.log(`  Success: ${result.success}`);
        this.assert(result.success === true, 'Mission success');
        this.assert(result.score.grade !== 'F', 'Not failing grade');
    }
    // Test 19: Mission System - Landing Zone Check
    testMissionSystemLandingZoneCheck() {
        console.log('\nTest 19: Mission System - Landing Zone Check');
        const system = new mission_1.MissionSystem();
        const zone = system.getLandingZone('lz_tranquility');
        // Zone coordinates convert to a specific position - create positions relative to that
        const outsidePos = { x: 100000, y: 100000, z: 1737400 };
        const outside = system.isInLandingZone(outsidePos, zone);
        console.log(`  Outside zone: ${outside}`);
        console.log(`  Zone radius: ${zone.radius}m`);
        this.assert(outside === false, 'Far position outside zone');
        this.assert(zone.radius > 0, 'Zone has valid radius');
    }
    // Test 20: Mission System - Get All Landing Zones
    testMissionSystemGetAllZones() {
        console.log('\nTest 20: Mission System - Get All Landing Zones');
        const system = new mission_1.MissionSystem();
        const zones = system.getAllLandingZones();
        console.log(`  Total zones: ${zones.length}`);
        this.assert(zones.length >= 4, 'Multiple zones available');
        this.assert(zones.some(z => z.difficulty === 'easy'), 'Has easy zone');
        this.assert(zones.some(z => z.difficulty === 'extreme'), 'Has extreme zone');
    }
    runAllTests() {
        console.log('=== MISSION SYSTEM TESTS ===');
        this.testLandingZoneGet();
        this.testLandingZoneGetAll();
        this.testLandingZoneFilterByDifficulty();
        this.testScoringPerfectLanding();
        this.testScoringPoorLanding();
        this.testScoringDifficultyMultiplier();
        this.testScoringLandingSpeed();
        this.testScoringPrecisionBonus();
        this.testMissionBuilderTraining();
        this.testMissionBuilderPrecision();
        this.testMissionBuilderChallenge();
        this.testChecklistAddRetrieve();
        this.testChecklistUpdateCompletion();
        this.testChecklistCompletionRate();
        this.testMissionSystemLoadMission();
        this.testMissionSystemCompleteObjectives();
        this.testMissionSystemCheckObjective();
        this.testMissionSystemCalculateScore();
        this.testMissionSystemLandingZoneCheck();
        this.testMissionSystemGetAllZones();
        this.printResults();
    }
}
// Run tests
const tests = new MissionTests();
tests.runAllTests();
// Export test count for CI
const exitCode = tests['failed'] > 0 ? 1 : 0;
process.exit(exitCode);
