module.exports = function (grunt) {
	var gruntConfig = {
		coffee: {
			back: {
				expand: true,
				cwd: 'src',
				src: ['**/*.coffee'],
				dest: 'bin',
				ext: '.js',
				options: {
					bare: true
				}
			}
		},
		watch: {
			default: {
				files: ['src/**/*'],
				tasks: ['default']
			}
		}
	};

	grunt.initConfig(gruntConfig);

	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-contrib-watch');

	grunt.registerTask('default', ['coffee']);
};