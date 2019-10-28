import logging



# F0401:  9,0: Unable to import 'webapp2'
# pylint: disable=F0401
import webapp2





app = webapp2.WSGIApplication(
    [],
    debug=True)


def main():
    # E0602:158,4:main: Undefined variable 'run_wsgi_app'
    run_wsgi_app(app)  # pylint: disable=E0602


if __name__ == "__main__":
    main()
