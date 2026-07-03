-- Seed the performance-report body template into reports.thetext (id = 1).
-- The app falls back to its built-in copy when this row is missing or empty,
-- so it is safe to run this at any time. Re-running replaces the stored text
-- with this default.
--
-- If the reports table already exists with a different shape, skip the CREATE
-- and just run the INSERT ... ON CONFLICT (adjusting columns as needed).

CREATE TABLE IF NOT EXISTS public.reports (
    id integer PRIMARY KEY,
    reportname text NOT NULL DEFAULT '',
    thetext text NOT NULL DEFAULT ''
);

INSERT INTO public.reports (id, reportname, thetext)
VALUES (1, 'Performance Report', $tpl$<div class="titlepage">
    {clinic_logo}
    <p class="tp-heading">Fitness Evaluation and Rehabilitation Plan</p>
    <p class="tp-phase">Phase 1</p>
    <p class="tp-patient">{patient_name}</p>
</div>
<div class="blankpage">&nbsp;</div>

<h1>Cervical, Lumbar &amp; Cardiovascular Physical Performance Test Report</h1>
<p class="subtitle">{report_date}</p>

<h2>Background</h2>
<p>Performance-based spinal assessments provide information about distinct domains of interest that are missing in a physical examination and self-report measure. Adding performance testing provides an assessment that increases the probability of improved patient outcomes. Physical disuse and neuromusculoskeletal weaknesses have been presented as major factors that can perpetuate chronic pain. Moreover, it has been found that exercises are effective preventive interventions for neck and back problems.</p>
<p>In the cervical spine, muscle endurance has been identified as an important variable in the prognosis of neck pain and headache disorders. Researchers have found reliability and validity in a battery of cervical physical performance measures: cervical flexor endurance and extensor endurance. Additionally, normative values have been established with gender subgroups.</p>
<p>In the lumbar spine, muscle endurance has been identified as an important variable in the prognosis of low back pain disorders. Several research teams have found reliability and validity in a battery of physical performance measures: lumbar extensor endurance, repeated sit-to-stand and fifty-foot fast walk. Additionally, normative values have been established with gender subgroups. During patient testing, each task was repeated twice (and averaged) within the test session, with the exception of the lumbar extensor endurance test (prone double straight-leg raise), which was performed once.</p>
<p>Cardiovascular fitness can be evaluated with a submaximal step test. Researchers have found reliability and validity in the Kasch Step Test. Additionally, normative values have been established with gender and aging subgroups.</p>

<h2>Examination</h2>
<p><strong>{patient_name}</strong> is a <strong>{age}</strong>-year-old <strong>{gender}</strong>. Pre-test blood pressure and heart rate were within normal ranges. Functional Rating Index score was <strong>{fri_score}</strong> (0-20 = minimal disability; 21-40 = moderate disability; 41-60 = severe disability; &gt;61 = very severe disability). Pain intensity was <strong>{pain}</strong> (0 = no pain, 4 = worst possible pain).</p>
{examination_findings}

<h2>Therapy Plan &amp; Goal</h2>
<p>{patient_name}'s performance was <strong>below satisfactory on {below_satisfactory_list}</strong>. We recommend supervised graded exercise rehabilitation for {patient_name}. The exercises will focus upon improving the endurance of the cervical and lumbar spine. Researchers recommend that exercise goals should aim above the mean to the "good to excellent" range because of the dose response of exercise therapy. Our goal is to improve the {goal_list} to the good range in the next {goal_months} months with re-evaluations at {reeval_days} days.</p>

<p class="signoff">Sincerely,<br><br>{physician_name}</p>

{normative_tables}$tpl$)
ON CONFLICT (id) DO UPDATE SET
    reportname = EXCLUDED.reportname,
    thetext = EXCLUDED.thetext;
