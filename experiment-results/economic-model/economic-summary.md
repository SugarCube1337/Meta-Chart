# Economic model summary

## Assumptions

- Manual lines per service per environment: 106.2
- Metachart fixed part: 239
- Metachart marginal service block: 13
- Average environment override: 24
- Estimated configuration processing rate: 120 lines/hour
- Initial metachart design cost: 4 hours

## Main conclusions

- Technical line-count break-even for 3 environments starts from 2 services.
- Economic break-even with initial design cost of 4 hours starts from about 3 services.
- For 5 services and 3 environments:
  - manual baseline: 1593 lines;
  - metachart: 376 lines;
  - reduction: 76.4%;
  - manual estimated effort: 13.28 hours;
  - metachart estimated effort including initial design: 7.13 hours;
  - net saving: 6.14 hours.

## Generated files

- break-even-by-services.csv
- break-even-services-hours.png
- net-saving-services.png
- lines-per-service.csv
- lines-per-service.png
- growth-by-environments.csv
- growth-by-environments.png
