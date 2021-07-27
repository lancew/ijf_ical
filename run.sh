echo "Running update..."
carton exec perl ijf_ical.pl > ijf.ics
echo "Committing..."
git add ijf.ics
git commit -m 'Update'
echo "Pushing..."
git push
echo "DONE"
