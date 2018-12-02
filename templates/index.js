if (process.env.NODE_ENV === 'production') {
  require('./bundle');
} else {
  require('./output/Main').main();
}
