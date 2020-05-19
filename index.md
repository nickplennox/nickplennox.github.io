# Quick Screenshot gallery

## Dashboard screen layouts

Please see below final layouts for the beta 1 release.

The iPhone models are, from left to right: iPhone 11 Pro Max, iPhone 11, iPhone X, iPhone 7/8 & iPhone SE. The size of screens varies from 6.5" to 4", so quite a challenge to get a design like this to be consistent.

Note that the space below regular payments at the default Dynamic Type setting is reserved to allow room for larger Dynamic Text sizes, as can be seen in the second screenshot in each pair below.

Also note the jumbo-sized rent due amount and bank balance treatment on the left-most three screens, with a smaller size on the fourth screen (iPhone 7) and the removal of this treatment completely on the fifth screen (iPhone SE).

### Rent due expanded

**Default Dynamic Type settings**
![1](https://nickplennox.github.io/assets/trc-beta1-default-1.png)

**Largest Dynamic Type settings**
![4](https://nickplennox.github.io/assets/trc-beta1-max-1.png)

### Bank account expanded

**Default Dynamic Type settings**
![2](https://nickplennox.github.io/assets/trc-beta1-default-2.png)

**Largest Dynamic Type settings**
![5](https://nickplennox.github.io/assets/trc-beta1-max-2.png)

### Regular payments expanded

**Default Dynamic Type settings**
![3](https://nickplennox.github.io/assets/trc-beta1-default-3.png)

**Largest Dynamic Text settings**
![6](https://nickplennox.github.io/assets/trc-beta1-max-3.png)

## Custom Pickers

### Calendar Picker

The Calendar Picker allows picking a start date for a recurring payment. The first selected date is shown in all cases, where there is another recurrance of the payment within the date range shown, that is also shown (for weekly or fortnightly payments).

Business rules are applied to present either the 1st to 28th of the month as valid start dates, or any day of the month, depending on the payment type.

![Calendar Picker](https://nickplennox.github.io/assets/calendar-picker.gif)

## Amount Picker

The Amount Picker allows for entering a currency amount directly, where the slider control does not allow the user to enter the amount that they wish to pay. A calculator-style input metaphor is used. The amount is automatically entered after the user types the second decimal place value and therefore no enter key is present. The delete key allows mistakes to be corrected during input.

![Amount Picker](https://nickplennox.github.io/assets/calc-input.gif)
