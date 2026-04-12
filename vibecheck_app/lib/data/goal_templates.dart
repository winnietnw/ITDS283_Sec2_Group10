import 'package:flutter/material.dart';

class GoalDayPlan {
  final int day;
  final String title;
  final String subtitle;
  final List<String> tasks;

  const GoalDayPlan({
    required this.day,
    required this.title,
    required this.subtitle,
    required this.tasks,
  });
}

class GoalTemplate {
  final String id;
  final String title;
  final String classification;
  final Color color;
  final Color accentColor;
  final List<GoalDayPlan> monthlyPlans;

  const GoalTemplate({
    required this.id,
    required this.title,
    required this.classification,
    required this.color,
    required this.accentColor,
    required this.monthlyPlans,
  });
}

int daysInMonth(DateTime date) {
  final nextMonth = (date.month < 12)
      ? DateTime(date.year, date.month + 1, 1)
      : DateTime(date.year + 1, 1, 1);
  return nextMonth.subtract(const Duration(days: 1)).day;
}

List<GoalDayPlan> _buildPlans({
  required int totalDays,
  required List<String> titles,
  required List<String> subtitles,
  required List<List<String>> taskPools,
}) {
  return List.generate(totalDays, (index) {
    final i = index % titles.length;
    return GoalDayPlan(
      day: index + 1,
      title: titles[i],
      subtitle: subtitles[i],
      tasks: taskPools[i],
    );
  });
}

List<GoalTemplate> buildGoalTemplatesForCurrentMonth() {
  final totalDays = daysInMonth(DateTime.now());

  return [
    GoalTemplate(
      id: 'goal_learning_academic_success',
      title: '30-Day All-Purpose Academic Success Method',
      classification: 'Learning',
      color: const Color(0xFFE9D9A8),
      accentColor: const Color(0xFF8F7149),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Time Management Skills',
          'Professional Knowledge Learning',
          'Problem-Solving Skills',
          'Expression Skills',
          'Innovation Capability',
          'Focus and Review',
        ],
        subtitles: const [
          'Create a daily task list and categorize it using the Four-Quadrant method.',
          'Spend 30 minutes building professional knowledge through reading or review.',
          'Analyze one small issue and write at least two solutions.',
          'Practice expressing ideas clearly through writing or speaking.',
          'Identify one improvement idea related to academic or personal work.',
          'Reflect on progress and refine what needs improvement.',
        ],
        taskPools: const [
          [
            'Prioritize tasks that are important and urgent.',
            'Break one large task into smaller steps.',
            'Set one focused study block and protect it from distractions.',
          ],
          [
            'Read one article or watch one lesson related to your field.',
            'Write a short summary of what you learned.',
            'Highlight one concept to review later.',
          ],
          [
            'Pick one challenge from study or daily life.',
            'List at least two possible solutions.',
            'Choose the most practical next action.',
          ],
          [
            'Write 5–8 sentences explaining one idea clearly.',
            'Practice speaking for 3 minutes on one topic.',
            'Revise wording for clarity and confidence.',
          ],
          [
            'Think of one improvement idea in study or workflow.',
            'Write why it could help.',
            'Note one action needed to test it.',
          ],
          [
            'Review today’s progress.',
            'Mark what went well.',
            'Adjust tomorrow’s plan based on today.',
          ],
        ],
      ),
    ),
    GoalTemplate(
      id: 'goal_learning_ielts_toefl',
      title: '30-Day IELTS and TOEFL Preparation Method',
      classification: 'Learning',
      color: const Color(0xFFF0AAAA),
      accentColor: const Color(0xFFD65F5F),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Vocabulary Expansion',
          'Listening Practice',
          'Reading Accuracy',
          'Writing Improvement',
          'Speaking Confidence',
          'Mock Review',
        ],
        subtitles: const [
          'Build active academic vocabulary through short daily drills.',
          'Train listening accuracy using short English clips.',
          'Improve reading speed and comprehension.',
          'Write concise, structured responses.',
          'Practice answering aloud with confidence.',
          'Review weak points from recent practice.',
        ],
        taskPools: const [
          [
            'Memorize 15 new academic words.',
            'Write one sentence for each of 5 words.',
            'Review yesterday’s vocabulary list.',
          ],
          [
            'Listen to a 3–5 minute English clip.',
            'Write down key points you understood.',
            'Replay once and fill missing details.',
          ],
          [
            'Read one short passage.',
            'Underline topic sentences.',
            'Answer 3 comprehension questions.',
          ],
          [
            'Write one short paragraph with clear structure.',
            'Check grammar and vocabulary choices.',
            'Rewrite one sentence more naturally.',
          ],
          [
            'Speak for 2 minutes on one topic.',
            'Record yourself once.',
            'Note one pronunciation issue to improve.',
          ],
          [
            'Review mistakes from recent practice.',
            'Choose one weak skill to focus on tomorrow.',
            'Write one clear improvement target.',
          ],
        ],
      ),
    ),
    GoalTemplate(
      id: 'goal_work_competitiveness',
      title: '30-Day Career Competitiveness Boost',
      classification: 'Work',
      color: const Color(0xFFF1A4A4),
      accentColor: const Color(0xFFD45858),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Career Positioning',
          'Professional Output',
          'Work Communication',
          'Execution Habit',
          'Problem Ownership',
          'Weekly Reflection',
        ],
        subtitles: const [
          'Clarify your strengths and career direction.',
          'Produce visible work that shows progress.',
          'Improve workplace communication and reporting.',
          'Build a consistent action habit.',
          'Take ownership of one work issue.',
          'Reflect and refine work performance.',
        ],
        taskPools: const [
          [
            'Write one strength you want to develop.',
            'Define one work goal for this week.',
            'Note one step to move closer to it.',
          ],
          [
            'Complete one visible output today.',
            'Document what you finished.',
            'List what remains next.',
          ],
          [
            'Write one concise update message.',
            'Clarify one request before acting.',
            'Summarize progress in 3 bullet points.',
          ],
          [
            'Start one important task before distractions.',
            'Finish one planned block without switching.',
            'Review execution quality at the end.',
          ],
          [
            'Pick one problem and define its cause.',
            'Suggest one realistic solution.',
            'Take one action to test it.',
          ],
          [
            'Review wins from the week.',
            'Review delays or blockers.',
            'Set one improvement for next week.',
          ],
        ],
      ),
    ),
    GoalTemplate(
      id: 'goal_work_improvement_plan',
      title: '2026 Year-Round Improvement Plan',
      classification: 'Work',
      color: const Color(0xFFDDC9B1),
      accentColor: const Color(0xFF9C7C5B),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Long-Term Goal Alignment',
          'System Improvement',
          'Self-Review',
          'Priority Planning',
          'Efficiency Improvement',
          'Progress Tracking',
        ],
        subtitles: const [
          'Keep daily actions aligned with longer goals.',
          'Improve one process or routine.',
          'Review your current level honestly.',
          'Choose priorities with intention.',
          'Remove waste and improve efficiency.',
          'Track performance and progress.',
        ],
        taskPools: const [
          [
            'Write one long-term goal.',
            'Match one action today to that goal.',
            'Remove one unrelated task.',
          ],
          [
            'Identify one step in your workflow to improve.',
            'Write a simpler version of it.',
            'Try the improved version once.',
          ],
          [
            'Review one area where you feel behind.',
            'Write one reason why.',
            'Set one next action to improve it.',
          ],
          [
            'Choose 3 priorities for the day.',
            'Rank them by impact.',
            'Complete the top one first.',
          ],
          [
            'Identify one repeated inefficiency.',
            'Write one fix.',
            'Test the fix today.',
          ],
          [
            'Check what you completed this week.',
            'Measure one thing that improved.',
            'Write what to continue next week.',
          ],
        ],
      ),
    ),

    GoalTemplate(
      id: 'goal_work_choices_destiny',
      title: 'Choices Determine Destiny: How to Make the Right Decisions',
      classification: 'Work',
      color: const Color(0xFFA8C7E3),
      accentColor: const Color(0xFF476E9A),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Decision Clarity',
          'Priority Check',
          'Option Review',
          'Risk Awareness',
          'Action Choice',
          'Reflection',
        ],
        subtitles: const [
          'Clarify the decision you need to make.',
          'Check what matters most first.',
          'Compare your options calmly.',
          'Think about possible risks before acting.',
          'Choose one practical action and move.',
          'Reflect on your decisions and what they teach you.',
        ],
        taskPools: const [
          [
            'Write down one decision you need to make.',
            'Define what outcome you want.',
            'Remove one unnecessary option.',
          ],
          [
            'List your top 3 priorities.',
            'Check whether your decision matches them.',
            'Cross out one low-impact distraction.',
          ],
          [
            'Write 2-3 possible options.',
            'Compare pros and cons briefly.',
            'Choose the strongest option for now.',
          ],
          [
            'Identify one possible downside.',
            'Write one way to reduce that risk.',
            'Avoid overthinking beyond what is useful.',
          ],
          [
            'Take one small step based on your choice.',
            'Commit to finishing that step today.',
            'Record what happened afterward.',
          ],
          [
            'Review whether today’s decision helped.',
            'Write one lesson you learned.',
            'Use that lesson tomorrow.',
          ],
        ],
      ),
    ),

    GoalTemplate(
      id: 'goal_interests_vision',
      title: '30-Day Diversified Vision Expansion',
      classification: 'Interests',
      color: const Color(0xFF9FCBE4),
      accentColor: const Color(0xFF4D86A9),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'New Perspective',
          'Creative Input',
          'Exploration Habit',
          'Curiosity Journal',
          'Small Experiment',
          'Insight Review',
        ],
        subtitles: const [
          'Explore one new idea or perspective.',
          'Consume thoughtful and creative content.',
          'Build a habit of active exploration.',
          'Write down questions and insights.',
          'Try a small new activity or approach.',
          'Review what surprised you this week.',
        ],
        taskPools: const [
          [
            'Read or watch something outside your usual field.',
            'Write one surprising idea from it.',
            'Note how it relates to your life.',
          ],
          [
            'Spend 20 minutes on creative content.',
            'Save one useful example.',
            'Explain why it stood out.',
          ],
          [
            'Try one unfamiliar topic today.',
            'Ask one question about it.',
            'Write one thing you want to explore more.',
          ],
          [
            'Write 3 curiosity questions.',
            'Choose one to think about deeply.',
            'Write one possible answer.',
          ],
          [
            'Try one small experiment or mini project.',
            'Observe the result.',
            'Write whether you want to continue.',
          ],
          [
            'Review interesting moments from the week.',
            'List one pattern you noticed.',
            'Choose one direction to explore next.',
          ],
        ],
      ),
    ),

    GoalTemplate(
      id: 'goal_interests_small_habits',
      title: '30 Small Habits to Make Life Better',
      classification: 'Interests',
      color: const Color(0xFFE9D9A8),
      accentColor: const Color(0xFF8F7149),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Tiny Habit Start',
          'Daily Reset',
          'Clutter Reduction',
          'Better Routine',
          'Mindful Choice',
          'Gentle Reflection',
        ],
        subtitles: const [
          'Start with one tiny habit that is easy to keep.',
          'Reset your day with a small useful action.',
          'Reduce one small source of clutter or friction.',
          'Improve one routine a little at a time.',
          'Make one better choice with intention.',
          'Reflect gently and continue consistently.',
        ],
        taskPools: const [
          [
            'Choose one habit that takes less than 5 minutes.',
            'Do it once today.',
            'Write how easy or hard it felt.',
          ],
          [
            'Do one reset action for your day.',
            'Finish it before distractions begin.',
            'Notice whether your day feels lighter.',
          ],
          [
            'Clear one small messy area.',
            'Throw away or organize one thing.',
            'Keep the space simple.',
          ],
          [
            'Improve one part of your routine.',
            'Repeat yesterday’s best habit.',
            'Track whether it feels smoother today.',
          ],
          [
            'Make one intentional healthy or productive choice.',
            'Notice what made it easier.',
            'Repeat that condition tomorrow.',
          ],
          [
            'Write one win from today.',
            'Write one habit worth keeping.',
            'Prepare to repeat it tomorrow.',
          ],
        ],
      ),
    ),

    GoalTemplate(
      id: 'goal_health_sudoku',
      title: '15-Minute Daily Sudoku Organizing Method',
      classification: 'Health',
      color: const Color(0xFFE9D9A8),
      accentColor: const Color(0xFF8F7149),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Focus Reset',
          'Pattern Training',
          'Mental Endurance',
          'Clarity Routine',
          'Attention Recovery',
          'Reflection Practice',
        ],
        subtitles: const [
          'Use short structured puzzle time to reset mental clutter.',
          'Train your brain to recognize patterns efficiently.',
          'Build consistency through light daily challenge.',
          'Create a calm thinking routine through structure.',
          'Recover concentration through focused practice.',
          'Reflect on progress and mental energy.',
        ],
        taskPools: const [
          [
            'Spend 15 minutes solving one sudoku puzzle.',
            'Avoid switching to other apps during the session.',
            'Write one word describing your focus afterward.',
          ],
          [
            'Solve one pattern-based puzzle step by step.',
            'Notice one strategy that helped you.',
            'Repeat the strategy in the next section.',
          ],
          [
            'Complete one puzzle without rushing.',
            'Pause once when stuck and reset calmly.',
            'Finish with a short review of mistakes.',
          ],
          [
            'Start at the same time as yesterday.',
            'Keep posture and breathing steady.',
            'Track whether concentration felt easier today.',
          ],
          [
            'Work in silence for 15 minutes.',
            'Reduce distractions before starting.',
            'Rate your attention from 1 to 5 after finishing.',
          ],
          [
            'Write one thing that improved today.',
            'Write one thing that still felt difficult.',
            'Choose one small adjustment for tomorrow.',
          ],
        ],
      ),
    ),
    GoalTemplate(
      id: 'goal_health_weight_loss',
      title: '30-Day Weight Loss Plan',
      classification: 'Health',
      color: const Color(0xFF9FCBE4),
      accentColor: const Color(0xFF3E87B5),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Hydration Habit',
          'Movement Routine',
          'Portion Awareness',
          'Light Cardio',
          'Healthy Plate',
          'Weekly Reset',
        ],
        subtitles: const [
          'Support your body with daily hydration.',
          'Build a gentle but consistent movement habit.',
          'Improve awareness of portions and eating pace.',
          'Increase activity through simple cardio.',
          'Balance meals with more nutritious choices.',
          'Reflect and reset for the next week.',
        ],
        taskPools: const [
          [
            'Drink water before your first meal.',
            'Carry a bottle and refill it once.',
            'Track whether you reached your water goal.',
          ],
          [
            'Walk for 20 minutes.',
            'Stretch for 5 minutes after walking.',
            'Note your energy level after moving.',
          ],
          [
            'Eat one meal slowly without multitasking.',
            'Reduce one unnecessary snack portion.',
            'Stop eating when comfortably full.',
          ],
          [
            'Do 20–30 minutes of light cardio.',
            'Keep a steady pace you can maintain.',
            'Log how long you moved today.',
          ],
          [
            'Add vegetables or fruit to one meal.',
            'Reduce one oily or sugary item.',
            'Build one plate with better balance.',
          ],
          [
            'Review your wins this week.',
            'Identify one eating habit to improve.',
            'Choose one realistic target for next week.',
          ],
        ],
      ),
    ),
    GoalTemplate(
      id: 'goal_health_attraction',
      title: 'Attraction: Let the Good Come to You',
      classification: 'Health',
      color: const Color(0xFF5E7BBB),
      accentColor: const Color(0xFFEAF0FF),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Positive Framing',
          'Gratitude Practice',
          'Energy Alignment',
          'Intentional Thoughts',
          'Self-Worth Reminder',
          'Quiet Reflection',
        ],
        subtitles: const [
          'Shift attention toward what is going well.',
          'Practice daily gratitude and appreciation.',
          'Protect your energy from unnecessary negativity.',
          'Guide your thoughts with intention.',
          'Build a stronger sense of self-worth.',
          'Reflect quietly on what you want to welcome in.',
        ],
        taskPools: const [
          [
            'Write 3 good things from today.',
            'Choose one positive thought to repeat.',
            'Avoid one negative spiral for 10 minutes.',
          ],
          [
            'Write 3 things you appreciate today.',
            'Say one thank-you out loud or in writing.',
            'Notice how gratitude changes your mood.',
          ],
          [
            'Take one break from draining input.',
            'Spend 10 minutes in a calm space.',
            'Choose one activity that makes you feel lighter.',
          ],
          [
            'Replace one limiting thought with a helpful one.',
            'Write one sentence about the life you want.',
            'Read it slowly once before sleep.',
          ],
          [
            'Write one strength you value in yourself.',
            'Do one small act of self-respect today.',
            'Let yourself feel proud of one thing.',
          ],
          [
            'Sit quietly for 5 minutes.',
            'Think about what you want to attract.',
            'End with one calm, hopeful sentence.',
          ],
        ],
      ),
    ),
    GoalTemplate(
      id: 'goal_health_anxiety_relief',
      title: '30-Day Anxiety and Stress Relief Plan',
      classification: 'Health',
      color: const Color(0xFFE7A3CB),
      accentColor: const Color(0xFF9D4C78),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Breathing Reset',
          'Grounding Exercise',
          'Stress Journal',
          'Body Relaxation',
          'Thought Release',
          'Gentle Reflection',
        ],
        subtitles: const [
          'Reset your nervous system with simple breathing.',
          'Return attention to the present moment.',
          'Reduce mental overload by writing things down.',
          'Release physical tension gently.',
          'Let go of one repetitive stressful thought.',
          'Reflect without judging yourself.',
        ],
        taskPools: const [
          [
            'Practice slow breathing for 3 minutes.',
            'Count each inhale and exhale calmly.',
            'Notice how your body feels afterward.',
          ],
          [
            'Name 5 things you can see.',
            'Name 4 things you can feel.',
            'Return your attention to the room around you.',
          ],
          [
            'Write down your main stressor today.',
            'Write one thing you can control.',
            'Write one thing you can release.',
          ],
          [
            'Stretch neck and shoulders for 5 minutes.',
            'Relax your jaw and hands consciously.',
            'Take one short body scan break.',
          ],
          [
            'Catch one anxious thought.',
            'Write a calmer alternative thought.',
            'Repeat the calmer version once.',
          ],
          [
            'Write one thing that helped today.',
            'Write one feeling you handled well.',
            'Prepare one soothing action for tomorrow.',
          ],
        ],
      ),
    ),
    GoalTemplate(
      id: 'goal_health_fitness',
      title: '30-Day Fitness Program',
      classification: 'Health',
      color: const Color(0xFFF0A7A7),
      accentColor: const Color(0xFFD45B5B),
      monthlyPlans: _buildPlans(
        totalDays: totalDays,
        titles: const [
          'Mobility Start',
          'Core Strength',
          'Lower Body Day',
          'Upper Body Day',
          'Cardio Endurance',
          'Recovery Review',
        ],
        subtitles: const [
          'Warm up and mobilize your body with intention.',
          'Build basic core strength consistently.',
          'Strengthen legs and lower body control.',
          'Improve upper body strength gradually.',
          'Train endurance with simple cardio.',
          'Recover and review progress.',
        ],
        taskPools: const [
          [
            'Do 5 minutes of dynamic stretching.',
            'Wake up your joints with light movement.',
            'Prepare your body for the session.',
          ],
          [
            'Complete one short core workout.',
            'Focus on controlled movement.',
            'Rest properly between sets.',
          ],
          [
            'Do one lower-body circuit.',
            'Keep form stable through each rep.',
            'Stretch legs after finishing.',
          ],
          [
            'Do one upper-body routine.',
            'Control posture during each movement.',
            'Reduce speed and focus on form.',
          ],
          [
            'Move for 20 minutes at moderate intensity.',
            'Keep your breathing steady.',
            'Log your duration and energy after.',
          ],
          [
            'Take a light recovery day.',
            'Stretch major muscle groups.',
            'Review which exercise felt strongest.',
          ],
        ],
      ),
    ),
  ];
}
